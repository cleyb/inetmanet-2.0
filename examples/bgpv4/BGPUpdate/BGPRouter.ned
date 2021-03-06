//
// Copyright (C) 2010 Helene Lageber
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program; if not, see <http://www.gnu.org/licenses/>.
//

package inet.examples.bgpv4.BGPUpdate;

import inet.util.MessageChecker;
import inet.transport.ITCP;
import inet.nodes.inet.NetworkLayer;
import inet.networklayer.ospfv2.OSPFRouting;
import inet.networklayer.ipv4.RoutingTable;
import inet.networklayer.common.InterfaceTable;
import inet.networklayer.bgpv4.BGPRouting;
import inet.linklayer.IWiredNic;
import inet.base.NotificationBoard;


//
// Example IP router with BGPv4 and OSPFv4 support.
//
module BGPRouter
{
    parameters:
        string routingFile = default("");
        string tcpType = default(firstAvailable("TCP","TCP_lwIP","TCP_NSC","TCP_None"));  // tcp implementation (e.g. ~TCP, ~TCP_lwIP, ~TCP_NSC) or ~TCPSpoof
    gates:
        inout pppg[] @labels(PPPFrame-conn);
        inout ethg[] @labels(EtherFrame-conn);
    submodules:
        notificationBoard: NotificationBoard {
            parameters:
                @display("p=52,44;i=block/control_s");
        }
        interfaceTable: InterfaceTable {
            parameters:
                @display("p=52,108;i=block/table_s");
        }
        routingTable: RoutingTable {
            parameters:
                IPForward = true;
                routerId = "auto";
                routingFile = routingFile;
                @display("p=52,172;i=block/table2_s");
        }
        ospf: OSPFRouting {
            parameters:
                @display("p=235,284,row;i=block/network2");
        }
        bgp: BGPRouting {
            parameters:
                @display("p=160,50;i=block/network");
        }
        snifferIn: MessageChecker {
            parameters:
                @display("i=block/uparrow_s;p=132,124");
        }
        snifferOut: MessageChecker {
            parameters:
                @display("i=block/downarrow_s;p=196,124");
        }
        tcp: <tcpType> like ITCP {
            parameters:
                @display("p=160,202;i=block/transport");
        }
        networkLayer: NetworkLayer {
            parameters:
                proxyARP = true;
                @display("p=120,284;i=block/layer;q=queue");
            gates:
                ifIn[sizeof(pppg)+sizeof(ethg)];
                ifOut[sizeof(pppg)+sizeof(ethg)];
        }
        ppp[sizeof(pppg)]: <default("PPPInterface")> like IWiredNic {
            parameters:
                @display("p=74,369,row,110;q=l2queue;i=block/ifcard");
        }
        eth[sizeof(ethg)]: <default("EthernetInterface")> like IWiredNic {
            parameters:
                @display("p=196,369,row,110;q=l2queue;i=block/ifcard");
        }
    connections allowunconnected:
        bgp.tcpOut --> { @display("m=s"); } --> snifferOut.in;
        bgp.tcpIn <-- { @display("m=s"); } <-- snifferIn.out;

        snifferOut.out --> { @display("m=s"); } --> tcp.appIn++;
        snifferIn.in <-- { @display("m=s"); } <-- tcp.appOut++;

        tcp.ipOut --> { @display("m=s"); } --> networkLayer.tcpIn;
        tcp.ipIn <-- { @display("m=s"); } <-- networkLayer.tcpOut;

        ospf.ipOut --> { @display("m=s"); } --> networkLayer.ospfIn;
        ospf.ipIn <-- { @display("m=s"); } <-- networkLayer.ospfOut;

        // connections to network outside
        for i=0..sizeof(pppg)-1 {
            pppg[i] <--> ppp[i].phys;
            ppp[i].upperLayerOut --> networkLayer.ifIn[i];
            ppp[i].upperLayerIn <-- networkLayer.ifOut[i];
        }

        for i=0..sizeof(ethg)-1 {
            ethg[i] <--> eth[i].phys;
            eth[i].upperLayerOut --> networkLayer.ifIn[sizeof(pppg)+i];
            eth[i].upperLayerIn <-- networkLayer.ifOut[sizeof(pppg)+i];
        }
}

