import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

class LoginScreenTV extends StatefulWidget {
  const LoginScreenTV({super.key});

  @override
  State<LoginScreenTV> createState() => _LoginScreenTVState();
}

class _LoginScreenTVState extends State<LoginScreenTV> {
  String androidId = 'Loading...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getAndroidId();
  }

  Future<void> _getAndroidId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      
      setState(() {
        androidId = androidInfo.id ?? 'Unknown ID ....';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        androidId = 'Error retrieving ID';
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  String _getHelpText(int index) {
    switch (index) {
      case 0:
        return 'Use directional buttons to navigate';
      case 1:
        return 'Press OK to select and continue';
      case 2:
        return 'Use Back button to return';
      default:
        return 'Navigation guide';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    
    bool isMobile = size.shortestSide < 600;
    bool isTablet = size.shortestSide >= 600 && size.shortestSide < 1200;
    bool isLandscape = orientation == Orientation.landscape;
    
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: _buildResponsiveLayout(isMobile, isTablet, isLandscape, size),
      ),
    );
  }

  Widget _buildResponsiveLayout(bool isMobile, bool isTablet, bool isLandscape, Size size) {
    if (isMobile && isLandscape) {
      return _buildMobileLandscapeLayout();
    }
    
    if (isMobile) {
      return _buildMobilePortraitLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/size.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildLoginForm(false, false, false),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/size.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildLoginForm(true, false, false),
        ),
      ],
    );
  }

  Widget _buildMobilePortraitLayout() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/size.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            _buildLoginForm(false, true, false),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLandscapeLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/size.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildLoginForm(false, true, true),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isTablet, bool isMobile, bool isLandscape) {
    final size = MediaQuery.of(context).size;

    // محاسبات سایز بر اساس دستگاه
    double getTitleFontSize() {
      if (isMobile) {
        return isLandscape ? 20 : 28;
      } else if (isTablet) {
        return isLandscape ? 24 : 32;
      } else {
        return 40;
      }
    }

    double getBodyFontSize() {
      if (isMobile) {
        return isLandscape ? 12 : 14;
      } else if (isTablet) {
        return isLandscape ? 14 : 16;
      } else {
        return 20;
      }
    }

    double getPaddingValue() {
      if (isMobile) {
        return isLandscape ? 12 : 16;
      } else if (isTablet) {
        return isLandscape ? 20 : 24;
      } else {
        return 40;
      }
    }

    double getSpacingValue() {
      if (isMobile) {
        return isLandscape ? 8 : 16;
      } else if (isTablet) {
        return isLandscape ? 12 : 20;
      } else {
        return 30;
      }
    }

    return Container(
      color: Colors.grey[850],
      padding: EdgeInsets.all(getPaddingValue()),
      child: Column(
        mainAxisAlignment: isMobile && isLandscape 
            ? MainAxisAlignment.center 
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
            Column(
              children: [
                Text(
                  'Login Zosign',
                  style: TextStyle(
                    fontSize: getTitleFontSize(),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: getSpacingValue()),
              ],
            ),
          
          // Login Card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(getPaddingValue()),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Device ID:',
                    style: TextStyle(
                      fontSize: getBodyFontSize(),
                      fontWeight: FontWeight.bold,
                      color: Colors.white60,
                    ),
                  ),
                  SizedBox(height: getSpacingValue() * 0.5),
                  
                  isLoading
                      ? SizedBox(
                          height: getBodyFontSize() * 2,
                          child: CircularProgressIndicator(),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: Text(
                            androidId,
                            style: TextStyle(
                              fontSize: getBodyFontSize() + 2,
                              fontWeight: FontWeight.w600,
                              color: Colors.yellow,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  
                  SizedBox(height: getSpacingValue()),
          
                  SizedBox(
                    width: isMobile && isLandscape ? size.width * 0.3 : double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle login action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 16,
                        ),
                      ),
                      child: Text(
                        'Login', 
                        style: TextStyle(
                          fontSize: getBodyFontSize() + 2,
                        )
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: getSpacingValue()),

         
          
            Container(
              height: isMobile ? 70 : 70,
              margin: EdgeInsets.only(top: getSpacingValue()),
              child: PageView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.all( 0.5),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[300],
                          size: getBodyFontSize(),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getHelpText(index),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: getBodyFontSize() - 1, 
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[300],
                          size: getBodyFontSize(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}