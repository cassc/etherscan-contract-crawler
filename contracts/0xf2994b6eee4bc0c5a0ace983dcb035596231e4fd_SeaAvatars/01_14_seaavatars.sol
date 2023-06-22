// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface SeaInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
}

contract SeaAvatars is ERC721, ERC721Enumerable, Ownable {
    bool public saleIsActive = false;
    bool public burned = false;
    address public SeaAddress = 0xccB6E4a1c42F4892cdE27A8bC2e50bbA0b43d224;
    SeaInterface SeaContract = SeaInterface(SeaAddress);
    
    constructor() ERC721("SeaAvatars", "SEAV") {
    }
     

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function toHashCode(uint256 value) internal pure returns (string memory) {
        uint256 i;

        bytes memory buffer = "000000";
        for(i=6;i>0;i--) {
            if (value % 16 < 10)
                buffer[i-1] = bytes1(uint8(48 + uint256(value % 16)));
            else
                buffer[i-1] = bytes1(uint8(55 + uint256(value % 16)));

            value /= 16;
        }
        return string(buffer);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    function getPolygon(uint256 num, string memory color, string memory op) internal pure returns (string memory) {
        uint256[180]memory xtypes =[
            4814428123379440877112789653708048739232650899662072877855038155387987431215,
            134090543,
            3213740837251487480304978222492611373843034917926543139373749086079167363288,
            3665448596379561495266568050510573499255299605025824809279735116735304552088,
            205484395792065916098301401717170874304911595874256154464498320,
            4978496874583640837093842564837635911112988777710182783287306338547366718674,
            2847423534786952485829505879377973299768746716665431702559283142857412987502,
            35140135382753,
            2990030449756037583316377534683801160820975666322594,
            633147047751871463082639347446,
            633250043510582197225664685096,
            783342371240660400615497362662867695169835591505009495153,
            3015605336097770010832060948773439899320263180355111271447081940574438532253,
            1699410383171683060484640923082407994735009912351540698902523680158858963667,
            2067439483755009076537239878613967120688171739225650558832839415147437291640,
            2110285635025633850782162448438909787314249243868635101044081548977791378060,
            1813537826634847775588271020849619009466237369690820983365919405283580390552,
            1433165981178011733008463800384150766019695303333840710976987787175893725835,
            1347834300580146900593882219877353796923237396140869764780512560971696623306,
            1588291142145332360308884532736805401102486146533600217899801854658095932103,
            1630640689404733378642505262896486732354314158877471864006247217340780175548,
            1926975200976366162727790765948535744022368363806555952276809889580033045183,
            2195729526611169200073088264115405134266050171528327914526689757427595025581,
            2266183416249769109687683253195421600011544355208010500246994655874713467054,
            1942021118171089200927872160880968143467387698704835635209143544230560220841,
            2026692120635480416902954766191778704951595844413918284067846871351766098126,
            2252931742901068372445672611749832774842961514843407512141469648329648975563,
            2295116187662235110121913666276726987468444668928175066731688914204036246718,
            2592194794286804437698157144159526339621523043225693230464121704378048799436,
            2535270053559044811589912991644676175666664223951765667507672669824291794632,
            2676810635330829446627987247531416732227338364894945326305024218158728837315,
            2676507767503271220336019071355421318369328191959582692781556145107637730497,
            2860260185232810836874932161100098492177796172019734599621174229889736083643,
            2704583530546838355578889545793450502804454913237751059045251025304634622638,
            2732605051757189469738771911402128307348469092831311049021474868234958504110,
            2689896882341260570152089198804438177341639211772304451963188924944556062881,
            2874339369183394173601732921210730487262146816407635719706621996970437346462,
            134063278,
            11401402070285144550100871971896250052146431669,
            11401442479798540347354564667579758730284697744,
            2010405393385468769754390500839040943260313875155174100691674881837603800274,
            53852718675364590822474638051961946119679634989037219218611160268927,
            2873152535253068203115307214512935299514021674337530122812293448446001082573,
            632967951439172729344733328545,
            2703590214691199062276704278272662481619631230524746364075007852563519075527,
            3142100272699584422061276135492595947566116804089604574541184736671832567449,
            2989437538194262125706135904879775746659906037333659,
            2732882416327165001845161696611165857660612391574224505373154795372861555376,
            511,
            2407752739435277468182135965268740961167067564356323244993211865623229981385,
            2718635756548816077094781045246157570894954467225593574078410329624519202986,
            205426318550813624678543263541887184093338878840179569528765611,
            783755749980388114187626910565273421423263977749007664810,
            2802230349547862087207944134484874423122711422731942543155255483070880492751,
            4033286330948968342802066104321959696267657300291049256998759985275710840448,
            2989426410341552234246661906532089360279329427827888,
            2703203069435399854974180652086783188110879736547100033428855629723775884484,
            3326681766720166569802217709619400280322460235055753081581802918103831117954,
            3736343546743753260211845024466212803851390170907039772609456547994386951852,
            205409056410469613002004354563412766279958914452316885766240416,
            1971616190158006219705968645019532586535831259808819755347658143630318153833,
            11399522681441707448144466669239173253050471147,
            1914414298019550117063508162120147874407892009683649735561803866455306738423,
            35134101066472,
            1205906187159667043478116698855989167391587791278914760228820903963052253383,
            9208186077033047238,
            1108535604507764213683166814513984193935977038616812534071790246938547877087,
            511,
            165898217922643309084526052680454256,
            1276275803054313493599806570260748153354263436358400765083857487700048243417,
            1178822342572881599758773592983319479796300992156451348075390679526609297106,
            9207483898066677967,
            740975772651252457144836420278673397610254157186597222250099236134980751977,
            2414117941576320369311410,
            632708923678708594065717615261,
            1458925500838540507418926026561993567301703685253672786264170589214896329935,
            1362215544816844226291935252053426049015218768525540613182698930612617390203,
            205358079224472907756417989573029084098844703882026101090076869,
            2405738554033416632426971367221281326733416003252598059526135764720845880057,
            205367565356852077129926225204268878140292779083361308042405991,
            2094799621356768638422789955858255696415450532913632148607982003334359841527,
            216385665523705520674157202371983031175832580637483984829524597222897451627,
            2414056423330995164691159,
            11397700635544049811140143993956400775937410739,
            1953753321857745697879799949839981476218506366288294591805006875595925160150,
            2414313723860810707829366,
            2413834197074852568406235,
            1007024817493647344034072868464098635223782697202574437333574124131465880276,
            978311935401717486461471199063926706147737078905916884262441267563763117176,
            1744463536117297771199500556841754719200382694378654872668579678780200630368,
            511,
            14112961311574784031995581858176719375774695975355569236051599162882701011,
            1897711303285596482765067278580384626287392383020712652244311076941978193104,
            134015680,
            53838512057721440562939736802025788259291144916640581635750671998583,
            53828861982961135492201427184879149672978060633158020975671450566856,
            1218549703504418858426162283162138827211025846478484793807547462127761523912,
            1178049449980952191072349915198487915111597729517606511759043444728495120489,
            1248613335570268749676909298256317029060994509812092552730532908634266442967,
            1009593031495819252828700569240846868741021889479975996220684736809035147948,
            511,
            2237333844498111748883215477507890751800256493258715525511056416630703471762,
            511,
            165929294059383718597136186708933768,
            165928665183444790299169218008267404,
            53845519538819855508960808442933283326529873565053054911387792911572,
            632953462932985502401346219733,
            11402537257086157492956168853500386529649441493,
            2338127278722570274363906040942801375633166264814527435739863412231291358938,
            632992172374068595235072070355,
            14116035176210511671108551609314867430245309605471104878804150874868631768,
            2989198070966187183905653156820517155486041008851669,
            1914165240659878124278093455124795799975637481046506062551521715814255628505,
            2239183573178341868630490435769242119124342703048732488176563775529780318423,
            783516542217681384326802153090181251758094015190434920149,
            205392594202743270705599732363469054786985168948493990009572567,
            2196696207197523970848110246220850787567375659661879630802303424358746760918,
            43496064942646834154564841992264090467026,
            2451344281097134209035305689338887225410243436567307749947473686735818932439,
            134038231,
            9210896242334838485,
            11403234498813872975814317136142915991533607641,
            2052946140791500114938153887393848933442548125195317854590544344108166871666,
            134024309,
            2414284504605938271190647,
            2414432961303085847740591,
            1840619951669604201410879954770232798770635410344762643704857699299414045884,
            2054740440345882338413182726751774799923504795098535273396345647260901121653,
            11401099814810876640669013063882522770837151408,
            2251164459629472805890764632980280277423766955907349854903606843989721679987,
            35133399578745,
            632965160288698604399670134412,
            632963006881331930588495022277,
            1786344573953401262130609349327547713072556579231105641242862738580471876815,
            2038589805006897792509112007954350735573250959223795959103614935773248814209,
            53842228122476702495773295789384926848390152018530179498957340490361,
            11401924403712846923563882592647883891447504561,
            165908440879873426276575088097426107,
            632895368158899369863413300935,
            1758268323525362595923532786314480328080018599735810783059475054768039464143,
            205391794314900404883493199233542293351979380310701105445663417,
            53851282851944209321420284640220371633171315667141036238171496339675,
            205423955338156824854771464258264672819344281274335154421196500,
            2577729327169094013913866036448034673223125940098247934601313183565024680666,
            11403452706877142101024583031628030006125753017,
            2989425896204408496798268877956759112715740736746173,
            2989368449265634237443441350612458333462874654075053,
            2747678523175029219050907904201247527951368373004693689322273898694758724798,
            9211915013402753212,
            3018393708817140741526826604469395450011717245499418109813008810463571847958,
            511,
            2578005993306738766272720493549290003641129654788059437799834430105042922263,
            205453891193239864721000310941609329333251635029516111844828853,
            14118791738016870176898609723966653060633868239941088994990407440431952147,
            43502367761593881992589959363221389672163,
            2564532975842800516717576589205430082896313342638360674066970560767747778788,
            2662345006453239351655121122284717271256484617132755706888769186188301527742,
            2535048710605151100156159681989605707947025469919326540865784635456694350004,
            633040586241434255942783689906,
            2662538093696171203523322518377730080565180711373728926410531419261132958943,
            35140541447393,
            165915365962175250832669694316052105,
            165910991072664731647969066886692541,
            165915364714563768096814076148908681,
            632905030222108565907283182269,
            165941773779047896865379588025428813,
            783636964467172242015624329953870136005131318572805084494,
            53851123756109542786880701376471183343334073926133237164143885237585,
            11404551990931083991178740329624445415109531480,
            11404377256599313706827886264374972514872168274,
            14118043174159213750512275332842345089131422252097273049880944104801145683,
            2879060666130226223903190413161288011004202157635526868141497339872999740254,
            134058846,
            1348437942946537774187992213237890796509601516299775525587402884344614759289,
            205303390594931779347596621228099093120336219627248210526632204,
            325906032892669080226535334041476325337775906709561789896225250520937317938,
            783278824392957924854232793030235970878250007250455810227,
            
            39501981766050205511763645938889413926815084847014363323784499591316483998465,
            63116260013956854871348073892089032591383598474601552283817845072970876017752,
            105184833074588551822140444288569933265217461830097108150028045964
            ];
            
            
        uint256 i;
        uint256 first_index;
        uint256 cur_num;
        uint256 k;
        uint256 pos;
        uint256 part;
        string memory res;
        uint256 result;
        
        part = (xtypes[177+(num/32)] / (256**(num%32)));
        first_index = part%256;
        res = '';
    
        for(i = first_index-1; i<=250; i++) {
            if (xtypes[i] == 0)
                break;
    
            cur_num= xtypes[i];    
            k=0;
            for(pos=0;pos<=27;pos++) {
                result = (cur_num /  (512 ** pos)) % 512;
                if (result == 511)
                    break;
    
                if (k%2 == 0) {
                        res = string(abi.encodePacked(res, toString(result*3), ','));

                }
                else {
                    res = string(abi.encodePacked(res, toString(result*3), ' '));

                }
                k++;
             }   
            if (result == 511)
                break;
        }

        return string(abi.encodePacked('<polygon opacity="',op,'" points="', res, '" fill="#',color,'" />'));
    
    }
    
    function tokenURI(uint256 tokenId) pure public override(ERC721)  returns (string memory) {
        uint256[21] memory xtypes;
        string[6] memory colors;

        string[40] memory parts;
        uint256[12] memory params;

        uint256 pos;
        uint256 i;

        uint256 rand = random(string(abi.encodePacked('SeaMan:4,413.70',toString(tokenId))));

        params[0] = 1 + (rand % 35); // pallette=
        params[1] = 1 + ((rand/100) % 4);// beard
        params[2] = 1 + ((rand/1000) % 7); // cap
        params[3] = 1 + ((rand/10000) % 4); // ear
        params[4] = 1 + ((rand/100000) % 3); // glass
        params[5] = 1 + ((rand/1000000) % 4); // tube
        params[6] = 1 + ((rand/10000000) % 3); // mount
        params[7] = 1 + ((rand/100000000) % 4); // ship
        params[8] = 1 + ((rand/1000000000) % 3); // palm


        xtypes[0] = 207574965379110640608216022545122747804297713611180780071335701350711199;
        xtypes[1] = 1761542274015381829561806442388166782076133553027523683407153450284725839;
        xtypes[2] = 1318910288827824010265619304243609725711044680336380489173166130084184176;
        xtypes[3] = 724683447042801548696569560081030497164719783953138574072045560454446233;
        xtypes[4] = 4043991994606567853415936212959853079208569424781326127295573659918631;
        xtypes[5] = 3299620775196419612115186638262901643665550060006145227261506178449515;
        xtypes[6] = 1379064599592568033484279104016888586992032077745986354509927570994841;
        xtypes[7] = 1135013754671932960620571453940853222564543354936625869472113926285806993;
        xtypes[8] = 57540304388934554663713641863205016852965651449422231770389600610037335;
        xtypes[9] = 427915806210161317796546874658782169965398785064314928279652029687658137;
        xtypes[10] = 1645042025731165747020947949356891617690279996847601383616229449670826306;
        xtypes[11] = 2684402825716469350937603156675849781186432913394870831023569145709657;
        xtypes[12] = 948653233187084859464575317686592139222615901473770245914362476756190;
        xtypes[13] = 1062866615187437586058037191382177644371875915535598913465368644642651782;
        xtypes[14] = 369124523636997250166839484954653248850396559059904420057491494716833881;
        xtypes[15] = 442037650556033164066111039525968221351328081129885970071961277633331199;
        xtypes[16] = 1759957955803961638370133336600426903615700431543302529351008072247517534;
        xtypes[17] = 1409708756458103978798054840171071616358807503498064799802928769236271104;
        xtypes[18] = 311015873917387065279390940900677905795687522088524788509100013598527838;
        xtypes[19] = 1762344858914181531007580128366350777462090319317585386749708457335562658;
        xtypes[20] = 568162619401703612682951583545078045287018669724037195709696111106719797;

    
        for(i=0;i<=5;i++) {
            pos = (params[0]-1) * 6 + i;
            colors[i] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        }

        parts[0] = string(abi.encodePacked('<?xml version="1.0" encoding="utf-8"?><svg xmlns="http://www.w3.org/2000/svg" width="1000px" height="1000px" viewBox="0 0 1000 1000"><linearGradient id="g" gradientUnits="userSpaceOnUse" x1="500" y1="1000" x2="500" y2="0"><stop offset="0.5" style="stop-color:#',colors[1],'"/><stop offset="1" style="stop-color:#',colors[3],'"/></linearGradient><rect fill="url(#g)" width="1000" height="1000"/>'));
        
        
        parts[0] = string(abi.encodePacked(parts[0],'<radialGradient id="s" cx="676" cy="326" r="100" gradientUnits="userSpaceOnUse"><stop  offset="0.5" style="stop-color:#FFFF9E"/><stop offset="1" style="stop-color:#',colors[1],'"/></radialGradient><circle opacity="0.5" fill="url(#s)" cx="676" cy="326" r="100"/><g>'));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(83 +params[7], colors[2], '0.7'),'<animateMotion path="m 0 0 h -5000" dur="1500s" repeatCount="indefinite" /></g>'));
        if (params[8] > 1 ) {
            parts[0] = string(abi.encodePacked(parts[0], '<g>',getPolygon(params[8] == 2 ? 88: 89, colors[3], '1'),'<animateMotion path="M 0 0 H ',(params[8] == 2 ? '15' : '-13'),' Z" dur="5s" repeatCount="indefinite"/></g>'));
        }

        parts[0] = string(abi.encodePacked(parts[0], '<rect x="0" y="532" opacity="0.2" fill="#',colors[2],'" width="1000" height="469"/><rect x="0" y="608" opacity="0.3" fill="#',colors[2],'" width="1000" height="397"/><rect x="0" y="707" opacity="0.75" fill="#',colors[2],'" width="1000" height="500"><animateMotion path="M 0 0 V 20 Z" dur="10s" repeatCount="indefinite" /></rect><rect x="0" y="837" fill="#',colors[2],'" width="1000" height="163.167"><animateMotion path="M 0 0 V 60 Z" dur="10s" repeatCount="indefinite" /></rect>'));

        parts[0] = string(abi.encodePacked(parts[0], getPolygon(80+params[6], colors[2], '0.1')));

        parts[0] = string(abi.encodePacked(parts[0], getPolygon(0, colors[3], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(1, colors[5], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(2, colors[3], '0.3')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(3, colors[3], '0.3')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(4, colors[0], '0.2')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(5, colors[0], '0.2')));
        
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(6, colors[4], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(7, colors[2], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(8, 'FFFFE6', '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(9, 'FFFFE6', '1')));

        parts[0] = string(abi.encodePacked(parts[0],'<circle fill="#',colors[2],'" cx="566" cy="406" r="7.3"/><circle opacity="0.66" fill="#FFFFFF" cx="570" cy="404" r="3"/><circle fill="#',colors[2],'" cx="414" cy="407" r="7.3"/><circle opacity="0.66" fill="#FFFFFF" cx="418" cy="404" r="3"/><g>'));
        
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(77, colors[2],'1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(78, colors[2], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(79, colors[4], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(80, colors[4], '1')));

        parts[0] = string(abi.encodePacked(parts[0],'<animate attributeName="opacity" values="0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0" dur="4s" repeatCount="indefinite" begin="0s"/></g>'));
        
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(9 +params[1]*2-1, colors[2], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(9 +params[1]*2, colors[3], '0.66')));
        
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(40 +params[3]*3-2, colors[3], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(40 +params[3]*3-1, colors[0], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(40 +params[3]*3, colors[0], '1')));

        parts[0] = string(abi.encodePacked(parts[0], getPolygon(52 +params[4]*4-3, colors[2], '0.85')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(52 +params[4]*4-2, colors[0], '0.35')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(52 +params[4]*4-1, colors[0], '0.35')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(52 +params[4]*4, colors[3], '1')));
        
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(17 +params[2]*3-2, colors[3], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(17 +params[2]*3-1, colors[5], '0.6')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(17 +params[2]*3, colors[5], '0.6')));
                
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(64 +params[5]*3-2, colors[5], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(64 +params[5]*3-1, colors[3], '1')));
        parts[0] = string(abi.encodePacked(parts[0], getPolygon(64 +params[5]*3, colors[3], '1')));
        
        parts[1] = string(abi.encodePacked('</svg> '));

        string memory output = string(abi.encodePacked(parts[0],parts[1]));
        

        
        parts[0] = '[{ "trait_type": "Palette", "value": "';
        parts[1] = toString(params[0]);
        parts[2] = '" }, { "trait_type": "Beard", "value": "';
        parts[3] = toString(params[1]);
        parts[4] = '" }, { "trait_type": "Cap", "value": "';
        parts[5] = toString(params[2]);
        parts[6] = '" }, { "trait_type": "Ear", "value": "';
        parts[7] = toString(params[3]);
        parts[8] = '" }, { "trait_type": "Glasses", "value": "';
        parts[9] = toString(params[4]);
        parts[10] = '" }, { "trait_type": "Tube", "value": "';
        parts[11] = toString(params[5]);
        parts[12] = '" }, { "trait_type": "Mountains", "value": "';
        parts[13] = toString(params[6]);
        parts[14] = '" }, { "trait_type": "Ship", "value": "';
        parts[15] = toString(params[7]);
        if (params[8] > 1) {
            parts[15] = string(abi.encodePacked(parts[15], 
             '" }, { "trait_type": "Palm", "value": "',toString(params[8]-1)));
        }
        parts[16] = '" }]';
        
        string memory strparams = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        strparams = string(abi.encodePacked(strparams, parts[6], parts[7], parts[8], parts[9], parts[10]));
        strparams = string(abi.encodePacked(strparams, parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));



        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Onchain Seaman", "description": "Onchain Seaman - beautiful avatar, completely generated OnChain","attributes":', strparams, ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function burnAll() public onlyOwner {
        burned = true;
    }
    
    function directMint(address to, uint256 tokenId) public onlyOwner {
        require(!burned, "Burned!");
        _safeMint(to, tokenId);
    }
    
    function mintMany(uint32[] memory ids) public {
        require(!burned, "Burned!");
        require(saleIsActive, "Sale must be active to mint tokens");

        for (uint i = 0; i < ids.length; i++) {
            require(SeaContract.ownerOf(ids[i]) == msg.sender, "Must own a Sea to mint token");
            _safeMint(msg.sender, ids[i]);
        }
    }
    
    function mintToken(uint tokenId) public {
        require(!burned, "Burned!");
        require(saleIsActive, "Sale must be active to mint tokens");
        require(SeaContract.ownerOf(tokenId) == msg.sender, "Must own a Sea to mint token");

        _safeMint(msg.sender, tokenId);
    }

    
}




/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}