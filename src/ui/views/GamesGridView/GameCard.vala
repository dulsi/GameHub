using Gtk;
using Gdk;
using Granite;
using GameHub.Data;
using GameHub.Utils;
using GameHub.UI.Widgets;

namespace GameHub.UI.Views
{
	public class GameCard: FlowBoxChild
	{
		public Game game;
		
		private Frame card;
		private Overlay content;
		private AutoSizeImage image;
		private Image src_icon;
		private Label label;
		
		private Box actions;
		private Button run;
		
		private const int CARD_WIDTH_MIN = 320;
		private const int CARD_WIDTH_MAX = 680;
		private const float CARD_RATIO = 0.467f; // 460x215
		
		construct
		{
			card = new Frame(null);
			card.get_style_context().add_class(Granite.STYLE_CLASS_CARD);
			card.get_style_context().add_class("gamecard");
			card.margin = 4;
			
			child = card;
			
			content = new Overlay();
			
			image = new AutoSizeImage();
			image.set_constraint(CARD_WIDTH_MIN, CARD_WIDTH_MAX, CARD_RATIO);
			
			src_icon = new Image();
			src_icon.valign = Align.START;
			src_icon.halign = Align.START;
			src_icon.margin = 8;
			src_icon.opacity = 0.5;
			src_icon.set_events(0);
			
			label = new Label("");
			label.xpad = 8;
			label.ypad = 8;
			label.hexpand = true;
			label.valign = Align.END;
			label.justify = Justification.CENTER;
			label.lines = 3;
			label.set_line_wrap(true);
			
			actions = new Box(Orientation.VERTICAL, 0);
			actions.get_style_context().add_class("actions");
			actions.hexpand = true;
			actions.vexpand = true;
			
			content.add(image);
			content.add_overlay(actions);
			content.add_overlay(label);
			content.add_overlay(src_icon);
			
			card.add(content);
			
			content.add_events(EventMask.ALL_EVENTS_MASK);
			content.enter_notify_event.connect(e => { card.get_style_context().add_class("hover"); });
			content.leave_notify_event.connect(e => { card.get_style_context().remove_class("hover"); });
			content.button_release_event.connect(e => { if(game.is_installed()) game.run(); else game.install(); });
			
			show_all();
		}
		
		public GameCard(Game game)
		{
			this.game = game;
			
			label.label = game.name;
			
			src_icon.pixbuf = FSUtils.get_icon(game.source.icon + "-white", 24);
			
			load_image.begin();
		}
		
		private async void load_image()
		{
			var hash = Checksum.compute_for_string(ChecksumType.MD5, game.image, game.image.length);
			var remote = File.new_for_uri(game.image);
			var cached = FSUtils.file(FSUtils.Paths.Cache.Images, hash + ".jpg");
			try
			{
				if(!cached.query_exists())
				{
					yield remote.copy_async(cached, FileCopyFlags.NONE);
				}
				image.set_source(new Pixbuf.from_file(cached.get_path()));
				
				if(game.is_installed()) card.get_style_context().add_class("installed");
			}
			catch(Error e)
			{
				error(e.message);
			}
		}
	}
}
