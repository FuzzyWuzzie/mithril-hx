
import buddy.*;
import mithril.M;
import mithril.M.m;
import mithril.MithrilNodeRender;

using StringTools;
using buddy.Should;

class ServerRenderingTests extends buddy.SingleSuite
{
	public function new() {
		var render = new MithrilNodeRender().render;
		var view : Vnodes;
		
		describe("MithrilNodeRender", {
			it("should render basic types to html", {
				view = m("h1", "Welcome!");
				render(view).should.be("<h1>Welcome!</h1>");

				view = m("div", null);
				render(view).should.be("<div></div>");

				view = m("h1", 123);
				render(view).should.be("<h1>123</h1>");

				view = m("h2", true);
				render(view).should.be("<h2>true</h2>");
				
				view = m("div", false);
				render(view).should.be("<div></div>");
			});
			
			it("should render css styles properly", {
				view = [
					m('h1', "Hello world"),
					m('.test', {style: {color: 'red', backgroundColor: 'blue'}}, "Server-side Mithril")
				];
				render(view).should.startWith('<h1>Hello world</h1><div ');
				render(view).should.contain('class="test"');
				render(view).should.match(~/\bstyle="(color:red|;|background-color:blue){3}"/);
				render(view).should.endWith('>Server-side Mithril</div>');
			});
			
			it("should render tags with attributes properly", {
				view = m(".foo");
				render(view).should.be('<div class="foo"></div>');
				
				view = m("[title=bar]");
				render(view).should.be('<div title="bar"></div>');

				view = m("[empty]", "ok");
				render(view).should.be('<div empty>ok</div>');

				view = m("[title='foo foo']", "ok");
				render(view).should.be('<div title="foo foo">ok</div>');

				view = m("p[title=\"bar bar\"]");
				render(view).should.be('<p title="bar bar"></p>');

				view = m("#layout");
				render(view).should.be('<div id="layout"></div>');

				view = m("span#layout", "ok");
				render(view).should.be('<span id="layout">ok</span>');
				
				view = m("input", {readonly: true});
				render(view).should.be("<input readonly>");

				// Attribute position could vary between platforms
				view = m("a#google.external[href='http://google.com']", "Google"); 
				render(view).should.contain('href="http://google.com"');
				render(view).should.contain('class="external"');
				render(view).should.contain('id="google"');
				render(view).should.startWith('<a ');
				render(view).should.endWith('>Google</a>');
			});
			
			it("should render combinations of static and dynamic attributes properly", {
				view = m(".foo", {className: "bar"});
				render(view).should.be('<div class="foo bar"></div>');

				view = m(".foo", {className: ""});
				render(view).should.be('<div class="foo"></div>');

				view = m(".foo", {"class": "bar"});
				render(view).should.be('<div class="foo bar"></div>');
			});
			
			it("should render self-closing tags properly", {
				view = m("hr");
				render(view).should.be('<hr>');
				
				view = m("meta[name=keywords][content='A test']");
				render(view).should.startWith('<meta ');
				render(view).should.endWith('>');
				render(view).should.contain('name="keywords"');
				render(view).should.contain('content="A test"');
			});
			
			it("should render nested virtual elements properly", {
				view = m("ul", [
					m("li", "item 1"),
					m("li", "item 2"),
				]);
				
				render(view).should.be("<ul><li>item 1</li><li>item 2</li></ul>");
				
				var links = [
					{title: "item 1", url: "/item1"},
					{title: "item 2", url: "/item2"},
					{title: "item 3", url: "/item3"}
				];
				
				view = [
					m('ul.nav', 
						links.map(function(link) {
							return m('li',
								m('a', { href: link.url }, link.title)
							);
						})
					)
				];
				
				render(view).should.be(
					'<ul class="nav"><li><a href="/item1">item 1</a></li>' +
					'<li><a href="/item2">item 2</a></li><li><a href="/item3">item 3</a></li></ul>'
				);				
			});
			
			it("should render trusted text as html", {
				view = m('p', '<not trusted>');
				render(view).should.be("<p>&lt;not trusted&gt;</p>");
				
				view = m('p', ['<not trusted>']);
				render(view).should.be("<p>&lt;not trusted&gt;</p>");
				
				view = m('p', M.trust('<trusted&>'));
				render(view).should.be("<p><trusted&></p>");
			});
			
			///// Messy tests ////////////////////////////////////////////////////////////////////////			
			
			it("should stub most m.methods", {
				var todoList = new TodoList();
		
				todoList.add("First one");
				todoList.add("Second <one>");
		
				for(todo in todoList) {
					todoList.setStatus(todo, true);
					break;
				}
				
				var component = new TodoComponent(todoList);
				var renderedList : String = render(component.view());
		
				renderedList.should.startWith('<div><input value=""><button>Add</button><span style="display:none"> Adding...</span><table><tr><td><input ');
			
				renderedList.should.contain('checked');
				renderedList.should.contain('type="checkbox"');
			
				renderedList.should.endWith('></td><td style="text-decoration:line-through">First one</td></tr><tr><td><input type="checkbox"></td><td style="text-decoration:none">Second &lt;one&gt;</td></tr></table></div>');
			});
			
			// Attributes come in a different order on many targets,
			// can't be bothered to make this fully testable.
			xit("should render complex compositions with indentation properly", {
				var render = new MithrilNodeRender("  ").render;
				var webshop = new webshop.Webshop();

				var output = render(webshop.view());
				output = ~/[\r\n]/g.replace(output, "");
				output = ~/\s+/g.replace(output, " ");

				var test = '<h1>Welcome!</h1>
<p>Select a category on the left to start shopping.</p>
<p>Built in Haxe &amp; Mithril. Source code: <a href="https://github.com/ciscoheat/mithril-hx/tree/master/example/webshop" target="_blank">https://github.com/ciscoheat/mithril-hx/tree/master/example/webshop</a>
</p>
<h2>Todo</h2>
<ul class="list-group">
  <li class="list-group-item" style="text-decoration:none">
    <input type="checkbox">
    <span style="margin-left:5px">Checkout page</span>
  </li>
  <li class="list-group-item" style="text-decoration:none">
    <input type="checkbox">
    <span style="margin-left:5px">Thank you page</span>
  </li>
  <li class="list-group-item" style="text-decoration:line-through">
    <input type="checkbox" checked>
    <span style="margin-left:5px">Make cart not change size when open and items are deleted</span>
  </li>
  <li class="list-group-item" style="text-decoration:none">
    <input type="checkbox">
    <span style="margin-left:5px">Enable use of arrow keys when navigating search results</span>
  </li>
  <li class="list-group-item" style="text-decoration:none">
    <input type="checkbox">
    <span style="margin-left:5px">URL slugs for products</span>
  </li>
  <li class="list-group-item" style="text-decoration:none">
    <input type="checkbox">
    <span style="margin-left:5px">Fix css for navbar and cart for low-res devices</span>
  </li>
  <li class="list-group-item" style="text-decoration:none">
    <input type="checkbox">
    <span style="margin-left:5px">Administration section...</span>
  </li>
</ul>';
				test = ~/[\r\n]/g.replace(test, "");
				test = ~/\s+/g.replace(test, " ");

				output.should.be(test);
			});
		});
	}
}