package App::Netdisco::Daemon::Worker::Interactive;

use Dancer qw/:moose :syntax :script/;
use Dancer::Plugin::DBIC 'schema';
use Try::Tiny;

use Role::Tiny;
use namespace::clean;

# add dispatch methods for interactive actions
with 'App::Netdisco::Daemon::Worker::Interactive::DeviceActions',
     'App::Netdisco::Daemon::Worker::Interactive::PortActions';

sub worker_body {
  my $self = shift;

  while (1) {
      my $jobs = $self->do('take_jobs', $self->wid, 'Interactive');

      foreach my $job (@$jobs) {
          my $target = 'set_'. $job->{action};
          next unless $self->can($target);

          # do job
          my ($status, $log);
          try {
              $job->{started} = scalar localtime;
              ($status, $log) = $self->$target($job);
          }
          catch {
              $status = 'error';
              $log = "error running job: $_";
              $self->sendto('stderr', $log ."\n");
          };

          $self->close_job($job, $status, $log);
      }

      sleep( setting('daemon_sleep_time') || 5 );
  }
}

sub close_job {
  my ($self, $job, $status, $log) = @_;

  try {
      schema('netdisco')->resultset('Admin')
        ->find($job->{job})
        ->update({
          status => $status,
          log => $log,
          started => $job->{started},
          finished => \'now()',
        });
  }
  catch { $self->sendto('stderr', "error closing job: $_\n") };
}

1;
