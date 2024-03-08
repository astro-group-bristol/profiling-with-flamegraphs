
import java.util.Random;
import uk.ac.starlink.pal.AngleDR;
import uk.ac.starlink.pal.Pal;

public class SkyLib {

    public static double[] randomShiftFlat( double lonDeg, double latDeg,
                                            double maxDeg ) {
        Random rnd =
            new Random( Double.doubleToLongBits( lonDeg * latDeg * maxDeg ) );
        return randomOffset( lonDeg, latDeg, maxDeg * rnd.nextDouble(), rnd );
    }

    public static double[] randomShiftGaussian( double lonDeg, double latDeg,
                                                double scaleDeg ) {
        Random rnd =
            new Random( Double.doubleToLongBits( lonDeg * latDeg * scaleDeg ) );
        return randomOffset( lonDeg, latDeg, scaleDeg * rnd.nextGaussian(),
                             rnd);
    }

    public static double[] randomOffset( double lonDeg, double latDeg,
                                         double dDeg, Random rnd ) {
        AngleDR tp =
            new AngleDR( Math.toRadians( lonDeg ), Math.toRadians( latDeg ) );
        double r = rnd.nextDouble() * 2 * Math.PI;
        double dRad = Math.toRadians( dDeg );
        double xi = dRad * Math.cos( r );
        double eta = dRad * Math.sin( r );
        AngleDR x = new AngleDR( xi, eta );
        AngleDR result = new Pal().Dtp2s( x, tp );
        return new double[] { Math.toDegrees( result.getAlpha() ),
                              Math.toDegrees( result.getDelta() ) };
    }

    public static Random random() {
        return new Random( -232323 );
    }
}
