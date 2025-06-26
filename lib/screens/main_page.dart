import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scuba_diving_admin_panel/color/color_palette.dart';
import 'package:scuba_diving_admin_panel/screens/most_favorited_products_page.dart';
import 'package:scuba_diving_admin_panel/screens/orders_page.dart';
import 'package:scuba_diving_admin_panel/screens/admin_product_page.dart';
import 'package:scuba_diving_admin_panel/screens/statistics_page.dart';
import 'package:scuba_diving_admin_panel/screens/top_viewed_products_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scuba Living Admin Panel',
          style: GoogleFonts.playfair(color: ColorPalette.white),
        ),
        backgroundColor: ColorPalette.primary,
        iconTheme: IconThemeData(color: ColorPalette.white),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: height * 0.03),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminProductPage()),
                );
              },
              child: Container(
                height: height * 0.12,
                margin: EdgeInsets.all(height * 0.01),
                decoration: BoxDecoration(
                  color: ColorPalette.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Products",
                  style: GoogleFonts.playfair(
                    fontSize: height * 0.03,
                    color: ColorPalette.white,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StatisticsPage()),
                );
              },
              child: Container(
                height: height * 0.12,
                margin: EdgeInsets.all(height * 0.01),
                decoration: BoxDecoration(
                  color: ColorPalette.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Statistics",
                  style: GoogleFonts.playfair(
                    fontSize: height * 0.03,
                    color: ColorPalette.white,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrdersPage()),
                );
              },
              child: Container(
                height: height * 0.12,
                margin: EdgeInsets.all(height * 0.01),
                decoration: BoxDecoration(
                  color: ColorPalette.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Shipping",
                  style: GoogleFonts.playfair(
                    fontSize: height * 0.03,
                    color: ColorPalette.white,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MostFavoritedProductsPage(),
                  ),
                );
              },
              child: Container(
                height: height * 0.12,
                margin: EdgeInsets.all(height * 0.01),
                decoration: BoxDecoration(
                  color: ColorPalette.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Most Favorited Products",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfair(
                      fontSize: height * 0.03,
                      color: ColorPalette.white,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TopViewedProductsPage(),
                  ),
                );
              },
              child: Container(
                height: height * 0.12,
                margin: EdgeInsets.all(height * 0.01),
                decoration: BoxDecoration(
                  color: ColorPalette.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Top View Products",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfair(
                      fontSize: height * 0.03,
                      color: ColorPalette.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
