package App::Netdisco::Web::Plugin::Device::Addresses;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;
use Dancer::Plugin::DBIC;

use NetAddr::IP::Lite ':lower';

use App::Netdisco::Web::Plugin;

register_device_tab({ id => 'addresses', label => 'Addresses' });

# device interface addresses
ajax '/ajax/content/device/addresses' => sub {
    my $ip = NetAddr::IP::Lite->new(param('q'));
    return unless $ip;

    my $set = schema('netdisco')->resultset('DeviceIp')
                ->search({ip => $ip->addr}, {order_by => 'alias'});
    return unless $set->count;

    content_type('text/html');
    template 'ajax/device/addresses.tt', {
      results => $set,
    }, { layout => undef };
};

true;