import java.util.EnumSet;

/**
 * Simple program which utilizes google's translation api to translate text from
 * one language to another.
 *
 * @author Eric Van Dewoestine
 */
public class Translate
{
  /**
   * Translate the given text from the source language to the target language.
   *
   * Example, translating from english to german.
   * java -cp google-api-translate-java-0.53.jar:. Translate "Hello World" en de
   *
   * @param args
   */
  public static final void main(String[] args)
    throws Exception
  {
    // print out a list of supported languages to be used by vim command
    // completion.
    if(args.length == 1 && "-c".equals(args[0])){
      // next version should be using enums
      //for (Enum lang : EnumSet.allOf(com.google.api.translate.Language.class)){
      for (String lang : com.google.api.translate.Language.validLanguages){
        System.out.print(lang + " ");
      }
      System.out.println();
      return;
    }

    if(args.length != 3){
      System.err.println("error: invalid arguments");
      System.out.println("Usage:");
      System.out.print("  java -cp google-api-translate-java-0.53.jar:. ");
      System.out.println("Translate \"Hello World\" en de");
      System.exit(1);
    }

    String text = args[0].trim();
    text = text.replaceAll("\n", " && ");

    String slang = args[1];
    String tlang = args[2];
    String translation =
      com.google.api.translate.Translate.translate(text, slang, tlang);
    translation = translation.replaceAll(" & & ", "\n");
    System.out.println(translation);

    System.exit(0);
  }
}
