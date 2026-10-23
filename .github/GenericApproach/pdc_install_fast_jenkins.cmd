echo on

set var1=%1
SHIFT
set var2=%1
SHIFT
set var3=%1
SHIFT
set var4=%1
SHIFT
set var5=%1
SHIFT
set var6=%1
SHIFT
set var7=%1
SHIFT
set var8=%1
SHIFT
set var9=%1
SHIFT
set var10=%1
SHIFT
set var11=%1
SHIFT
set var12=%1
SHIFT
set var13=%1
SHIFT
set var14=%1
SHIFT
set var15=%1
SHIFT
set var16=%1
SHIFT
set var17=%1
SHIFT
set var18=%1
SHIFT
set var19=%1
SHIFT
set var20=%1
SHIFT
set var21=%1
SHIFT
set var22=%1
SHIFT
set var23=%1
SHIFT
set var24=%1
SHIFT
set var25=%1
SHIFT
set var26=%1
SHIFT
set var27=%1
SHIFT
set var28=%1
SHIFT
set var29=%1
SHIFT
set var30=%1
SHIFT
set var31=%1
SHIFT
set var32=%1
SHIFT
set var33=%1
SHIFT
set var34=%1
SHIFT
set var35=%1
SHIFT
set var36=%1
SHIFT
set var37=%1
SHIFT
set var38=%1
SHIFT
set var39=%1
SHIFT
set var40=%1
SHIFT
set var41=%1
SHIFT
set var42=%1
SHIFT
set var43=%1
SHIFT
set var44=%1
SHIFT
set var45=%1
SHIFT
set var46=%1
SHIFT
set var47=%1
SHIFT
set var48=%1
SHIFT
set var49=%1
SHIFT
set var50=%1
SHIFT
set var51=%1
SHIFT
set var52=%1
SHIFT
set var53=%1
SHIFT
set var54=%1
SHIFT
set var55=%1
SHIFT
set var56=%1
SHIFT
set var57=%1
SHIFT
set var58=%1
SHIFT
set var59=%1
SHIFT
set var60=%1
SHIFT
set var61=%1
SHIFT
set var62=%1
SHIFT
set var63=%1
SHIFT
set var64=%1

set application=D:/Jenkins/Tools/RunAsCurrentUser.exe
set script=D:/Jenkins/GenericApproach/pdc_install_fast_side_pc.cmd
set inputParameters=%var1% %var2% %var3% %var4% %var5% %var6% %var7% %var8% %var9% %var10% %var11% %var12% %var13% %var14% %var15% %var16% %var17% %var18% %var19% %var20% %var21% %var22% %var23% %var24% %var25% %var26% %var27% %var28% %var29% %var30% %var31% %var32% %var33% %var34% %var35% %var36% %var37% %var38% %var39% %var40% %var41% %var42% %var43% %var44% %var45% %var46% %var47% %var48% %var49% %var50% %var51% %var52% %var53% %var54% %var55% %var56% %var57% %var58% %var59% %var60% %var61% %var62% %var63% %var64%

call %application% "%script% %inputParameters%"
