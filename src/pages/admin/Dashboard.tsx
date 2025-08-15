import { motion } from 'framer-motion';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Users, Shield, HardDrive, Activity } from 'lucide-react';

export default function Dashboard() {
  const stats = [
    { title: 'Total Users', value: '1,234', change: '+12%', icon: Users, color: 'primary' },
    { title: 'Active Sessions', value: '89', change: '+5%', icon: Activity, color: 'secondary' },
    { title: 'Storage Used', value: '2.4GB', change: '+8%', icon: HardDrive, color: 'accent' },
    { title: 'Security Events', value: '12', change: '-25%', icon: Shield, color: 'primary' },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-3xl font-bold neon-text-primary mb-2">Dashboard Overview</h2>
        <p className="text-muted-foreground">Monitor your system's key metrics and performance.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <motion.div
              key={stat.title}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <Card className="admin-card">
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium text-muted-foreground">
                    {stat.title}
                  </CardTitle>
                  <Icon className={`h-4 w-4 ${stat.color === 'primary' ? 'text-primary' : stat.color === 'secondary' ? 'text-secondary' : 'text-accent'}`} />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold neon-text-primary">{stat.value}</div>
                  <p className="text-xs text-muted-foreground">
                    <span className={stat.change.startsWith('+') ? 'text-green-400' : 'text-red-400'}>
                      {stat.change}
                    </span>
                    {' '}from last month
                  </p>
                </CardContent>
              </Card>
            </motion.div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="admin-card">
          <CardHeader>
            <CardTitle className="neon-text-primary">Recent Activity</CardTitle>
            <CardDescription>Latest system events and user actions</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex items-center gap-3 p-3 rounded-lg bg-muted/20">
                  <div className="w-2 h-2 bg-primary rounded-full animate-pulse"></div>
                  <div>
                    <p className="text-sm font-medium">User action {i}</p>
                    <p className="text-xs text-muted-foreground">2 minutes ago</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card className="admin-card">
          <CardHeader>
            <CardTitle className="neon-text-primary">System Status</CardTitle>
            <CardDescription>Current system health and performance</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-sm">Database</span>
                <div className="status-active">Healthy</div>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm">Authentication</span>
                <div className="status-active">Online</div>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm">Storage</span>
                <div className="status-active">Available</div>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm">API</span>
                <div className="status-active">Responsive</div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}