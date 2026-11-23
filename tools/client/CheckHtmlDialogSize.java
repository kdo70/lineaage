import net.sf.l2j.gameserver.network.serverpackets.NpcHtmlMessage;

class CheckHtmlDialogSize {
    static Object field(Object message, String name) throws Exception {
        var field = message.getClass().getDeclaredField(name);
        field.setAccessible(true);
        return field.get(message);
    }
    static void check(NpcHtmlMessage message, String html, int width, int height) throws Exception {
        message.setHtml(html);
        if (!field(message, "_htmlWindowWidth").equals(width) || !field(message, "_htmlWindowHeight").equals(height))
            throw new AssertionError(html);
        if (((String)field(message,"_html")).contains("dialog-size")) throw new AssertionError("Directive leaked to client");
    }
    public static void main(String[] args) throws Exception {
        var message = new NpcHtmlMessage(0);
        check(message,"<!-- dialog-size: 800x600 --><html><body>Test</body></html>",800,600);
        check(message,"<html><!-- DIALOG-SIZE: 500 X 350 --><body>Test</body></html>",500,350);
        check(message,"<html><body>Standard</body></html>",0,0);
        check(message,"<!-- dialog-size: 999999999999x600 --><html/>",0,0);
        check(message,"<!-- dialog-size: 1x600 --><html/>",0,0);
        check(message,"<!-- dialog-size: wrong --><html/>",0,0);
        check(message,"<!-- dialog-size: 800x600 --><!-- dialog-size: 500x350 --><html/>",800,600);
        message.setWindowSize(500,350);
        check(message,"<!-- dialog-size: 800x600 --><html/>",800,600);
        if (!field(message,"_windowWidth").equals(500)) throw new AssertionError("Java override lost");
        System.out.println("PASS: HTML dimensions, whitespace, reset, invalid values, duplicate removal, Java override");
    }
}
