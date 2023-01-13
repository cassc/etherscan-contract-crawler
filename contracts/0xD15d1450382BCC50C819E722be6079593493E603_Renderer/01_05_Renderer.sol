//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./SVG.sol";
import "./Utils.sol";
import "./Strings.sol";

contract Renderer {
    using Strings for uint256;

    function render(uint256 id, uint160 sqrtPriceX96) public view returns (string memory) {

        uint p = 1000000000000/((uint(sqrtPriceX96) / (2**96))**2);
        string memory t;
        string memory t2;
        uint tid = id;
 
        if(p < 900){
            t = '-12.237903';
            t2 = '+13.754622';
        }
        else if(p >= 900 && p < 1100){
            t = '-10.357903';
            t2 = '+10.154622';
        }        
        else if(p >= 1100 && p < 1300){
            t = '-8.477903';
            t2 = '+6.554622';
        }
        else if(p >= 1300 && p < 1500){
            t = '-6.597903';
            t2 = '+2.954622';
        }
        else if(p >= 1500 && p < 1700){
            t = '-4.717903';
            t2 = '-0.645378';
        }
        else if(p >= 1700 && p < 1900){
            t = '-2.837903';
            t2 = '-4.245378';
        }
        else if(p >= 1900 && p < 2100){
            t = '-0.957903';
            t2 = '-7.845378';
        }
        else if(p >= 1100 && p < 2300){
            t = '+0.922097';
            t2 = '-11.445378';
        }
        else if(p >= 2300 && p < 2500){
            t = '+2.802097';
            t2 = '-15.045378';
        }
        else if(p >= 2500 && p < 2700 ){
            t = '+4.682097';
            t2 = '-18.645378';
        }
        else{
            t = '+5.237903';
            t2 = '-20.754622';
        }

        return
            string.concat(
                '<svg id="ejbrX7hcI0m1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 -40 250 250" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" style="background-color:hsl(',Strings.toString(random(id, "sk")),', 100%, 80%)"><style type="text/css"><![CDATA[text { font-family: Comic Sans MS, monospace; font-size: 21px;} .h1 {font-size: 40px; font-weight: 600;}]]></style>',
                '<path d="M43.532138,161.525794C26.211909,161.401111,14.270961,191.839849,16.44733,210h153.245886c.91561-1.477597.77527-15.559346,0-18.798493-2.374011-4.687895-12.852309-12.76429-19.670023-17.255565v-2.982799L43.532138,161.525794Z" fill="hsl(',Strings.toString(random(id, "zs")),', 100%, 80%)" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>',
                '<path d="M44.222435,158.93565l-.690297,2.590143c22.65338,20.366154,97.998935,22.133799,102.285558,10.650476L44.222435,158.93565Z" transform="translate(.000001 0.000001)" fill="hsl(',Strings.toString(random(id, "gd")),', 100%, 80%)" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>',
                '<path d="M43.532136,158.49722c-7.193302-2.769057-10.444341-30.915268-7.740564-36.734878c1.581709-11.225501,14.605325-45.413136,25.878472-44.478717c3.526311-10.184046,12.206964-26.700433,22.245631-32.578418c12.443459-7.959621,35.430003-6.5256,45.862888,5.623036c18.43452-12.69121,43.619055-11.759689,46.917207,11.94895c4.87381,1.881459,16.467992,7.588132,15.519504,11.092933c3.398305,1.656981,7.47851,4.828263,6.431164,6.688412c1.419352,1.63023,3.250288,5.294635,3.197039,6.494117.462895,7.446375-2.526177,7.555465-2.682545,8.040315.140906,1.089141-.042849,2.199499-.304967,2.377076l-6.537007,3.932641c-1.935198,3.983228-8.503127,8.819683-12.97255,9.883848c5.881069,4.956369,12.77806,15.386767,12.426191,21.343545l-17.944995,23.381718c-2.564065,4.791131-13.218884,12.855194-24.756826,15.87742-29.31475,6.01402-82.30797,1.314429-105.538642-12.891998Z" transform="translate(.000002 0.000004)" fill="hsl(',Strings.toString(random(id, "gd")),', 100%, 80%)" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>',
                '<path d="M86.592717,64.41687c16.482487-13.850871,46.131488-8.494201,59.224979,11.506176l-1.502183,3.036121c5.412521-7.654394,30.962345-8.658517,47.899762-5.589037" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>',
                '<path d="M198.64644,80.773196c-11.400157-7.255727-37.260528-8.153347-52.022301-.714654-20.590116-10.167056-41.921015-1.725712-51.29075,5.109402-2.498722-.131482-7.840703.072146-10.683962.341886q-1.131959,1.278591.488703,4.188393l9.351363.882692" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>',
                '<path d="M94.708039,90.154346c5.621156-4.783526,14.123932-11.328923,20.88214-11.824138c17.079192-1.468538,27.595235.836671,32.91401,6.02218.839106,3.769071-.506592,7.799519-1.88005,9.33971-8.357155,12.318918-49.740308,5.340315-51.9161-3.537752" transform="translate(.000001 0)" fill="#fff" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M129.778565,50.328247l5.988827,12.44162c10.892791-1.784701,31.325951-2.403401,40.928379-.49267" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>',
                '<path d="M135.767393,62.769867l-2.461097.888161" transform="translate(.000001 0.000001)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M89.668593,81.453608c2.180419-.820613,5.097682-.692132,6.873883-2.494441c7.754278-7.868259,28.832931-12.042289,46.975652-6.156319" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M201.927627,87.209386c-1.639056-3.753661-11.334577-7.241307-18.245804-8.250221-19.985423-1.85188-36.330847,6.364466-35.813438,16.299794c10.247289,7.262045,36.067059,4.369992,51.292549-.665986c1.190259-.211368,2.673807-3.502358,2.766693-7.383587Z" transform="translate(0 0.000002)" fill="#fff" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M95.33339,98.342955c18.612914,8.414789,54.137873,11.294508,52.018152-4.650858" transform="translate(0 0.000001)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>',
                '<path d="M115.59018,116.452662c4.437639-1.281605,15.034965-6.561408,21.042576-10.179414" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M162.922898,114.452112l-11.368622-5.193579c7.037372,2.918569,21.908424,3.084569,29.730172.940569" transform="translate(0 0.000002)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M60.328241,89.698223l1.341804-13.125731" transform="translate(.000001 0)" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M74.78809,149.078656c1.272988,4.142417,4.561915,9.521442,9.127587,9.856995" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><ellipse rx="9.339762" ry="8.670245" transform="matrix(1.2 0 0 1.15 173.740726 89.3)" stroke-width="0"/><ellipse rx="10.153149" ry="10.25217" transform="matrix(1.1 0 0 1 119.6 89.7)" stroke-width="0"/><path d="M121.733431,85.167944c4.911004-.497861,3.369709,3.128709,1.523244,3.390027-1.301345-.124312-3.128018-2.686331-1.523244-3.390027Z" transform="translate(.000002 0.000003)" fill="#fff" stroke="#fff" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round"/>',
                '<ellipse rx="1.080641" ry="0.893174" transform="matrix(1.047442 0.073244-.069756 0.997564 116.294214 82.96638)" fill="#fff" stroke-width="0"/><ellipse rx="0.628259" ry="0.570124" transform="matrix(.987688 0.156434-.156434 0.987688 116.860169 89.128099)" fill="#fff" stroke-width="0"/><path d="M178.303345,87.921005c-1.061843.259131-2.076819.36987-2.999997,0-.215379-.6875-.223257-2.084292-.000003-2.753061.844646-.777778,1.884074-.767565,3-.034739.363815.683472.268946,2.021873,0,2.7878Z" fill="#fff" stroke="#fff" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round"/><ellipse rx="0.91" ry="0.769518" transform="matrix(.987688 0.156434-.156434 0.987688 170.712392 88.823404)" fill="#fff" stroke-width="0"/>',
                '<ellipse rx="1.490167" ry="1.344534" transform="translate(170.390167 82.744534)" fill="#fff" stroke-width="0"/>',
                svg.text(
                    string.concat(
                        svg.prop('x', '20'),
                        svg.prop('y', '10'),
                        svg.prop('font-size', '22'),
                        svg.prop('fill', 'black'),
                        svg.prop('stroke', 'black'),
                        svg.prop('stroke-width', '.75')
                    ),
                    string.concat(
                        '$',
                        svg.cdata(Strings.toString(p))
                    )
                ),
                svg.text(
                    string.concat(
                        svg.prop('x', '85'),
                        svg.prop('y', '205'),
                        svg.prop('font-size', '13'),
                        svg.prop('fill', 'black'),
                        svg.prop('stroke', 'black'),
                        svg.prop('stroke-width', '.5')
                    ),
                    string.concat(
                        '#',
                        svg.cdata(Strings.toString(id))
                    )
                ),
                svg.path(
                    string.concat(
                        svg.prop('d',
                            string.concat(
                                'M176.840325,146.819499c-32.885923,',t,'-80.096184,3.729987-82.350831',t2
                                )
                            ),
                        svg.prop('transform', 'translate(.995091 0)'),
                        svg.prop('fill', 'none'),
                        svg.prop('stroke', '#000'),
                        svg.prop('stroke-width', '22'),
                        svg.prop('stroke-linecap', 'round')
                    ),
                    utils.NULL
                ),
                svg.path(
                    string.concat(
                        svg.prop('d',
                            string.concat(
                                'M176.840325,146.819499c-32.885923,',t,'-80.096184,3.729987-82.350831',t2
                                )
                            ),                        
                        svg.prop('transform', 'translate(.000001 0)'),
                        svg.prop('fill', 'none'),
                        svg.prop('stroke', string.concat('hsl(',Strings.toString(random(tid, "lp")),', 100%, 80%)')),
                        svg.prop('stroke-width', '19'),
                        svg.prop('stroke-linecap', 'round')
                    ),
                    utils.NULL
                ),
                svg.path(
                    string.concat(
                        svg.prop('d',
                            string.concat(
                                'M176.840325,146.819499c-32.885923,',t,'-80.096184,3.729987-82.350831',t2
                                )
                            ),                        
                        svg.prop('transform', 'translate(.000001 0)'),
                        svg.prop('fill', 'none'),
                        svg.prop('stroke', '#000'),
                        svg.prop('stroke-width', '1.5'),
                        svg.prop('stroke-linecap', 'round')
                    ),
                    utils.NULL
                ),
                '<path d="M178.303344,136.60599c2.492544-.105922,9.961753-2.485239,13.469257-4.029921c9.403394,6.231565-4.706179,13.091591-15.076829,14.24343" transform="translate(.000001 0)" fill="hsl(',Strings.toString(random(tid, "lp")),', 100%, 80%)" stroke="#000" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/><line x1="-103" y1="6" x2="-8" y2="6" transform="translate(125 14.074212)" fill="none" stroke="#000" stroke-width="8" stroke-linecap="round"/><line x1="-103" y1="6" x2="-8" y2="6" transform="translate(125 14.074212)" fill="none" stroke="hsl(',Strings.toString(random(tid, "lp")),', 100%, 80%)" stroke-width="4.8" stroke-linecap="round"/>',
                '</svg>'
            );
    }

    function random(uint256 id, string memory el) public pure returns (uint) {
        uint r = uint(keccak256(abi.encodePacked(id, el))) % 359;
        return(r+1);
    }

}