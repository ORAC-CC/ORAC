"""Variables and classes used throughout the ORAC scripts."""


#-----------------------------------------------------------------------------
#----- GLOBAL VARIABLES ------------------------------------------------------
#-----------------------------------------------------------------------------

# Names of the possible Pavolonis cloud classes
ALL_TYPES = ('CLEAR', 'SWITCHED_TO_WATER', 'FOG', 'WATER', 'SUPERCOOLED',
             'SWITCHED_TO_ICE', 'OPAQUE_ICE', 'CIRRUS', 'OVERLAP',
             'PROB_OPAQUE_ICE', 'PROB_CLEAR')

# Colours used when printing to screen
COLOURING = {
    'pass'    : 'green',
    'warning' : 'light yellow',
    'error'   : 'red',
    'text'    : 'cyan',
    'header'  : 'light cyan',
    'timing'  : 'magenta'
}

#-----------------------------------------------------------------------------
#----- EXCEPTIONS AND WARNINGS -----------------------------------------------
#-----------------------------------------------------------------------------

class OracError(Exception):
    """Copy of Exception class to differentiate script errors from system."""
    pass

class FileMissing(OracError):
    def __init__(self, desc, filename):
        OracError.__init__(self, 'Could not locate {:s}: {:s}'.format(desc,
                                                                      filename))
        self.desc = desc
        self.filename = filename

class BadValue(OracError):
    def __init__(self, variable, value):
        OracError.__init__(self, 'Invalid value for {:s}: {:s}'.format(variable,
                                                                       value))
        self.variable = variable
        self.value = value

class OracWarning(UserWarning):
    pass

class Regression(OracWarning):
    def __init__(self, filename, variable, col, desc):
        import re
        import sys

        regex = re.search(r'_R(\d+)(.*)\.(.+)\.nc$', filename)
        if sys.stdout.isatty():
            text = '{:s}) {:s}: \C{{{:s}}}{:s}'.format(
                regex.group(3), variable, COLOURING[col], desc)
        else:
            text = '{:s}) {:s}: {:s}'.format(
                regex.group(3), variable, desc)
        OracWarning.__init__(self, text, 'text')

class InconsistentDim(Regression):
    def __init__(self, filename, variable, dim0, dim1):
        Regression.__init__(self, filename, variable, 'error',
                            'Inconsistent dimensions ({:d} vs {:d})'.format(
                                 dim0, dim1))

class FieldMissing(Regression):
    def __init__(self, filename, variable):
        Regression.__init__(self, filename, variable, 'warning',
                            'Field not present in one file')

class RoundingError(Regression):
    def __init__(self, filename, variable):
        Regression.__init__(self, filename, variable, 'error',
                            'Unequal elements')

class Acceptable(Regression):
    def __init__(self, filename, variable):
        Regression.__init__(self, filename, variable, 'pass',
                            'Acceptable variation')


#-----------------------------------------------------------------------------
#----- CONVIENIENCE CLASSES --------------------------------------------------
#-----------------------------------------------------------------------------
class FileName:
    """Parses L1B or ORAC filenames to determine the instrument and
    measurement time.

    Methods:
    job_name: Generates a unique descriptor of this file.
    root_name: Calculates the filename ORAC will produce for this file.

    Attributes:
    l1b (str): Name of the level 1B imager file.
    geo (str): Name of the corresponding geolocation file.
    sensor (str): Capitalised name of the instrument.
    platform (str): Name of the satellite platform, formatted for the
        preprocessor.
    inst (str): Combined sensor/platform, formatted for the main processor.
    time (datetime): tart time of the orbit/granule.
    dur (timedelta): Expected duration of the file.
    oractype (str): For an ORAC output, describes the type of file.
        Equals None otherwise.
    predef (bool): True if the sensor can accept predefined geolocation.
    noaa (str): The number of this AVHRR sensor (1, 2, or 3).
    """

    def __init__(self, in_dir, filename):
        import datetime
        import os
        import re

        self.l1b = filename

        # Attempt AATSR L1B filename
        m = re.search(
            'ATS_TOA_1P([A-Za-z]{4})(?P<year>\d{4})(?P<month>\d{2})'
            '(?P<day>\d{2})_(?P<hour>\d{2})(?P<min>\d{2})(?P<sec>\d{2})_'
            '(?P<duration>\d{7})(?P<phase>\d)(?P<cycle>\d{4})_'
            '(?P<rel_orbit>\d{5})_(?P<abs_orbit>\d{5})_(?P<count>\d{4})\.N1',
            filename
        )
        if m:
            self.sensor   = 'AATSR'
            self.platform = 'Envisat' # For preprocessor
            self.inst     = 'AATSR'   # For main processor
            self.time = datetime.datetime(
                int(m.group('year')), int(m.group('month')), int(m.group('day')),
                int(m.group('hour')), int(m.group('min')), int(m.group('sec')), 0
            )
            self.dur = datetime.timedelta(seconds=int(m.group('duration')))
            self.geo = filename
            self.oractype = None
            self.predef   = False
            return

        # Attempt ATSR2 L1B filename
        m = re.search(
            'AT2_TOA_1P([A-Za-z]{4})(?P<year>\d{4})(?P<month>\d{2})'
            '(?P<day>\d{2})_(?P<hour>\d{2})(?P<min>\d{2})(?P<sec>\d{2})_'
            '(?P<duration>\d{7})(?P<phase>\d)(?P<cycle>\d{4})_'
            '(?P<rel_orbit>\d{5})_(?P<abs_orbit>\d{5})_(?P<count>\d{4})\.E2',
            filename
        )
        if m:
            self.sensor   = 'ATSR2'
            self.platform = 'ERS2'  # For preprocessor
            self.inst     = 'ATSR2' # For main processor
            self.time = datetime.datetime(
                int(m.group('year')), int(m.group('month')), int(m.group('day')),
                int(m.group('hour')), int(m.group('min')), int(m.group('sec')), 0
            )
            self.dur = datetime.timedelta(seconds=int(m.group('duration')))
            self.geo = filename
            self.oractype = None
            self.predef   = False
            return

        # Attempt MODIS L1B filename
        m = re.search(
            'M(?P<platform>[OY])D021KM\.A(?P<year>\d{4})(?P<doy>\d{3})\.'
            '(?P<hour>\d{2})(?P<min>\d{2})\.(?P<collection>\d{3})\.'
            '(?P<proc_time>\d{13}).*hdf', filename
        )
        if m:
            self.sensor = 'MODIS'
            if m.group('platform') == 'O':
                self.platform = 'TERRA'       # For preprocessor
                self.inst     = 'MODIS-TERRA' # For main processor
            else: # == 'Y'
                self.platform = 'AQUA'
                self.inst     = 'MODIS-AQUA'
            self.time = (datetime.datetime(
                int(m.group('year')), 1, 1, int(m.group('hour')),
                int(m.group('min')), 0, 0
            ) + datetime.timedelta(days=int(m.group('doy')) - 1))
            self.dur  = datetime.timedelta(minutes=5) # Approximately
            self.geo  = ('M' + m.group('platform') + 'D03.A' + m.group('year') +
                         m.group('doy') + '.' + m.group('hour') +
                         m.group('min') + '.' + m.group('collection') + '.*hdf')
            self.oractype = None
            self.predef   = False
            return

        # Attempt reformatted AVHRR L1B filename
        m = re.search(
            'noaa(?P<platform>\d{1,2})_(?P<year>\d{4})(?P<month>\d{2})'
            '(?P<day>\d{2})_(?P<hour>\d{2})(?P<min>\d{2})_(\d{5})_satproj_'
            '(\d{5})_(\d{5})_avhrr.h5', filename
        )
        if m:
            self.sensor   = 'AVHRR'
            self.platform = 'noaa' + m.group('platform')
            self.inst     = 'AVHRR-NOAA' + m.group('platform')
            self.time = datetime.datetime(
                int(m.group('year')), int(m.group('month')), int(m.group('day')),
                int(m.group('hour')), int(m.group('min')), 0, 0
            )
            self.dur  = datetime.timedelta(seconds=6555) # Guessing
            # The following may be problematic with interesting dir names
            self.geo  = filename.replace('_avhrr.h5', '_sunsatangles.h5')
            self.oractype = None
            self.predef   = False
            return

        # Default AVHRR filename format produced by pygac (differs from
        # DWD produced L1b data)
        m = re.search(
            'ECC_GAC_avhrr_noaa(?P<platform>\d{1,2})_(\d{5})_(?P<year>\d{4})'
            '(?P<month>\d{2})(?P<day>\d{2})T(?P<hour>\d{2})(?P<min>\d{2})'
            '(\d{3})Z_(\d{8})T(\d{7})Z.h5', filename
        )
        if m:
            self.sensor   = 'AVHRR'
            self.platform = 'noaa' + m.group('platform')
            self.inst     = 'AVHRR-NOAA' + m.group('platform')
            # The time specification could be fixed, as the pygac file
            # names include start and end times, to 0.1 seconds
            self.time = datetime.datetime(
                int(m.group('year')), int(m.group('month')), int(m.group('day')),
                int(m.group('hour')), int(m.group('min')), 0, 0
            )
            self.dur  = datetime.timedelta(seconds=6555) # Guessing
            self.geo  = filename.replace('ECC_GAC_avhrr_',
                                         'ECC_GAC_sunsatangles_')
            self.oractype = None
            self.predef   = False
            return

        # Attempt SEVIRI L1B filename in NAT format
        m = re.search(
            'MSG(?P<platform>\d{1})-SEVI-MSG(\d+)-(\d+)-NA-(?P<year>\d{4})'
            '(?P<month>\d{2})(?P<day>\d{2})(?P<hour>\d{2})(?P<min>\d{2})'
            '(?P<sec>[\d\.]+)Z-(.*).nat', filename
        )
        if m:
            self.sensor   = 'SEVIRI'
            self.platform = 'MSG'+m.group('platform')
            self.inst     = 'SEVIRI'+m.group('platform')
            self.time     = datetime.datetime(
                int(m.group('year')), int(m.group('month')), int(m.group('day')),
                int(m.group('hour')), int(m.group('min')), float(m.group('sec')),
                0
            )
            self.dur      = datetime.timedelta(seconds=900) # Guessing
            self.geo      = filename
            self.oractype = None
            self.predef   = True
            return

        # Attempt SEVIRI L1B filename for segment HRT format
        m = re.search(
            'H-000-MSG(?P<platform>\d{1})_+-MSG(\d+)_+-_+-EPI_+-(?P<year>\d{4})'
            '(?P<month>\d{2})(?P<day>\d{2})(?P<hour>\d{2})(?P<min>\d{2})'
            '-_+', filename
        )
        if m:
            self.sensor   = 'SEVIRI'
            self.platform = 'MSG'+m.group('platform')
            self.inst     = 'SEVIRI'+m.group('platform')
            self.time     = datetime.datetime(
                int(m.group('year')), int(m.group('month')), int(m.group('day')),
                int(m.group('hour')), int(m.group('min')), 0, 0
            )
            self.dur      = datetime.timedelta(seconds=900) # Guessing
            self.geo      = filename
            self.oractype = None
            self.predef   = True
            return

        # Attempt SEVIRI L1B filename for Met Office format
        m = re.search(
            'MSG_(?P<year>\d{4})(?P<month>\d{2})(?P<day>\d{2})(?P<hour>\d{2})'
            '(?P<min>\d{2}).*h5', filename
        )
        if m:
            self.sensor   = 'SEVIRI'
            for fdr in in_dir:
                tmp = os.path.join(fdr, filename)
                if os.path.isfile(tmp):
                    self.platform = _determine_platform_from_metoffice(tmp)
            self.inst     = 'SEVIRI3'
            self.time     = datetime.datetime(
                int(m.group('year')), int(m.group('month')), int(m.group('day')),
                int(m.group('hour')), int(m.group('min')), 0, 0
            )
            self.dur      = datetime.timedelta(seconds=900) # Guessing
            self.geo      = filename
            self.oractype = None
            self.predef   = True
            return

        # Processed ORAC output
        m = re.search(
            '(?P<project>\w+)-(?P<product>.+)-(?P<sensor>\w+)_(?P<processor>\w+)'
            '_(?P<platform>\w+)_(?P<year>\d{4})(?P<month>\d{2})(?P<day>\d{2})'
            '(?P<hour>\d{2})(?P<min>\d{2})_R(?P<revision>\d+)(?P<phase>\w*)\.'
            '(?P<filetype>\w+)\.nc', filename
        )
        if m:
            self.sensor   = m.group('sensor')
            self.platform = m.group('platform')
            if 'ATSR' in m.group('sensor'):
                # SAD file names don't include platform for ATSR instruments
                self.inst = m.group('sensor')
            else:
                self.inst = m.group('sensor') + '-' + m.group('platform').upper()
            self.time = datetime.datetime(
                int(m.group('year')), int(m.group('month')), int(m.group('day')),
                int(m.group('hour')), int(m.group('min')), 0, 0
            )
            self.dur = None
            self.geo = None
            self.predef = False
            self.oractype = m.group('filetype')
            self.processor = m.group('processor')
            self.revision = m.group('revision')
            self.project = m.group('project')
            self.product_name = m.group('product')
            return

        raise OracError('Unexpected filename format - ' + filename)

    def job_name(self, revision=None, tag='run'):
        """Returns a formatted description of this orbit."""
        if revision is None:
            revision = self.revision
        return self.time.strftime('{}_%M-%H-%d-%m-%Y_R{}_{}'.format(
            self.inst, revision, tag
        ))

    def root_name(self, revision=None, processor=None, project=None,
                  product_name=None):
        """Returns the ORAC filename for this file."""
        if revision is None:
            revision = self.revision
        if processor is None:
            processor = self.processor
        if project is None:
            project = self.project
        if product_name is None:
            product_name = self.product_name

        desc = '_'.join((
            self.sensor, processor, self.platform,
            self.time.strftime('%Y%m%d%H%M'), "R{}".format(revision)
        ))
        return '-'.join((project, product_name, desc))

    @property
    def noaa(self):
        plat = int(self.platform[4:])
        if plat in (6, 8, 10):
            return '1'
        elif plat in (7, 9, 11, 12, 13, 14):
            return '2'
        elif plat in (15, 16, 17, 18, 19):
            return '3'
        else:
            raise ValueError("Unknown AVHRR platform: "+self.platform)


def _determine_platform_from_metoffice(filename):
    from h5py import File

    with File(filename) as data:
        platform = data["MSG/Prologue/GeneralInfo"][0][0]

    if 321 > platform > 324:
        raise ValueError("Unrecognised platform number {}".format(platform))

    return "MSG{}".format(platform - 320)

#-----------------------------------------------------------------------------
#----- INSTRUMENT/CLASS DEFINITIONS ------------------------------------------
#-----------------------------------------------------------------------------

# Map wavelengths available on each instrument to their channel numbers
def _dict_from_list(l):
    return dict(zip(l, range(1,len(l)+1)))

MAP_WVL_TO_INST = {
    'AATSR': _dict_from_list((
        0.55, 0.67, 0.87, 1.6, 3.7, 11., 12., -0.55, -0.67, -0.87,
        -1.6, -3.7, -11., -12.
    )),
    'AVHRR': _dict_from_list((0.67, 0.87, 1.6, 3.7, 11., 12.)),
    'HIMAWARI': _dict_from_list((
        0.47, 0.51, 0.67, 0.87, 1.6, 2.3, 3.7, 6.2, 6.9, 7.3,
        8.6, 9.6, 10., 11., 12., 13.3
    )),
    'MODIS': _dict_from_list((
        0.67, 0.87, 0.47, 0.55, 1.2, 1.6, 2.1, 0.41, 0.44, 0.49,
        0.53, 0.551, 0.667, 0.678, 0.75, 0.869, 0.91, 0.936, 0.94, 3.7,
        3.96, 3.959, 4.05, 4.466, 4.516, 1.375, 6.715, 7.325, 8.55, 9.73,
        11., 12., 13.3, 13.6, 13.9, 14.2
    )),
    'SEVIRI': _dict_from_list((
        0.67, 0.87, 1.6, 3.7, 6.25, 7.35,  8.7, 9.7, 11., 12., 13.3
#        0.67, 0.81, 1.64, 3.92, 6.25, 7.35,  8.7, 9.7, 11., 12., 13.3
    )),
    'VIIRS': _dict_from_list((
        0.41, 0.44, 0.49, 0.55, 0.67, 0.75, 0.87, 1.2, 1.4, 1.6,
        2.3, 3.7, 4.1, 8.6, 1.1, 12.
    ))
}


class Invpar():
    """Container for settings to pass to an ORAC retrieval
    Member variables:
    var - Name of the element of the state vector
    ap  - A priori value to use
    fg  - First guess of this value
    sx  - A priori uncertainty on this value
    """

    def __init__(self, var, ap=None, fg=None, sx=None):
        self.var = var
        if ap:
            self.ap = ap
            if fg is None:
                self.fg = ap
        if fg:
            self.fg = fg
        if sx:
            self.sx = sx

    def driver(self):
        """Output lines for a driver file to specify these settings"""
        driver = ''
        if self.ap != None:
            driver += "\nCtrl%XB[{:s}] = {}".format(self.var, self.ap)
        if self.fg != None:
            driver += "\nCtrl%X0[{:s}] = {}".format(self.var, self.fg)
        if self.sx != None:
            driver += "\nCtrl%Sx[{:s}] = {}".format(self.var, self.sx)
        return driver


class ParticleType():
    """Container for an ORAC particle type
    Member variables:
    inv - Tuple of Invpars giving settings to pass to retrieval
    wvl - Wavelengths used (negative implies the second view)
    sad - SAD file directory to use
    ls  - If true, process land and sea separately
    """

    def __init__(self,
                 name,
                 inv = (),
                 wvl = (0.55, 0.67, 0.87, 1.6, -0.55, -0.67, -0.87, -1.6),
                 sad = "CCI_A70-A79",
                 ls = True):
        self.name = name
        self.inv = inv
        self.wvl = wvl
        self.sad = sad
        self.ls = ls

    def sad_dir(self, sad_dirs, inst):
        from glob import glob
        from os.path import join

        for fdr in sad_dirs:
            if "AVHRR" in inst.sensor:
                fdr_name = join(fdr, inst.sensor.lower() + "-" +
                                inst.noaa + "_" + self.sad)
            else:
                fdr_name = join(fdr, inst.sensor.lower() + "_" + self.sad)

            file_name = "_".join((inst.sensor+"*", self.name, "RBD", "Ch*.sad"))

            # SAD files stored in subdirectories
            if len(glob(join(fdr_name, file_name))) > 0:
                return fdr_name

            # All files in one directory
            if len(glob(join(fdr, file_name))) > 0:
                return fdr

        raise FileMissing("Sad Files", str(sad_dirs))

# Using non-imager LUTs and Baum properties at Greg's recommendation
SETTINGS = {}
SETTINGS['WAT'] = ParticleType("WAT", wvl=(0.67, 0.87, 1.6, 3.7, 11, 12),
                               sad="WAT", ls=False)
SETTINGS['ICE'] = ParticleType("ICE", wvl=(0.67, 0.87, 1.6, 3.7, 11, 12),
                               sad="ICE_baum", ls=False)

tau = Invpar('ITau', ap=-1.0, sx=1.5)
SETTINGS['A70'] = ParticleType("A70", inv=(tau,Invpar('IRe',ap=0.0856,sx=0.15)))
SETTINGS['A71'] = ParticleType("A71", inv=(tau,Invpar('IRe',ap=-0.257,sx=0.15)))
SETTINGS['A72'] = ParticleType("A72", inv=(tau,Invpar('IRe',ap=-0.257,sx=0.15)))
SETTINGS['A73'] = ParticleType("A73", inv=(tau,Invpar('IRe',ap=-0.257,sx=0.15)))
SETTINGS['A74'] = ParticleType("A74", inv=(tau,Invpar('IRe',ap=-0.257,sx=0.15)))
SETTINGS['A75'] = ParticleType("A75", inv=(tau,Invpar('IRe',ap=-0.0419,sx=0.15)))
SETTINGS['A76'] = ParticleType("A76", inv=(tau,Invpar('IRe',ap=0.0856,sx=0.15)))
SETTINGS['A77'] = ParticleType("A77", inv=(tau,Invpar('IRe',ap=-0.0419,sx=0.15)))
SETTINGS['A78'] = ParticleType("A78", inv=(tau,Invpar('IRe',ap=-0.257,sx=0.15)))
SETTINGS['A79'] = ParticleType("A79", inv=(tau,Invpar('IRe',ap=-0.848,sx=0.15)))