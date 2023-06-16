// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// This is a revised version of the revised version of the original EtherRock contract 0x41f28833Be34e6EDe3c58D1f597bef429861c4E2 with all the rocks removed and rock properties replaced by tulips.
// The original contract at 0x41f28833Be34e6EDe3c58D1f597bef429861c4E2 had a simple mistake in the buyRock() function where it would mint a rock and not a tulip. The line:
// require(rocks[rockNumber].currentlyForSale == true);
// Had to check for the existance of a tulip, as follows:
// require(tulips[tulipNumber].currentlyForSale == true);
// Therefore in the original contract, anyone could buy anyone elses rock whereas they should have been buying a tulip (regardless of whether the owner chose to sell it or not)

contract EtherTulip is ERC721("EtherTulip", unicode"🌷") {
    struct Tulip {
        uint256 listingTime;
        uint256 price;
        uint256 timesSold;
    }

    mapping(uint256 => Tulip) public tulips;

    uint256 public latestNewTulipForSale;

    address public immutable feeRecipient;

    event TulipForSale(uint256 tulipNumber, address owner, uint256 price);
    event TulipNotForSale(uint256 tulipNumber, address owner);
    event TulipSold(uint256 tulipNumber, address buyer, uint256 price);

    constructor(address _feeRecipient) {
        // set fee recipient
        feeRecipient = _feeRecipient;
        // mint founder tulip to yours and only
        ERC721._mint(address(0x777B0884f97Fd361c55e472530272Be61cEb87c8), 0);
        // initialize auction for second tulip
        latestNewTulipForSale = 1;
        tulips[latestNewTulipForSale].listingTime = block.timestamp;
    }

    // Dutch-ish Auction

    function currentPrice(uint256 tulipNumber) public view returns (uint256 price) {
        if (tulipNumber == latestNewTulipForSale) {
            // if currently in auction
            uint256 initialPrice = 1000 ether;
            uint256 decayPeriod = 1 days;
            // price = initial_price - initial_price * (current_time - start_time) / decay_period
            uint256 elapsedTime = block.timestamp - tulips[tulipNumber].listingTime;
            if (elapsedTime >= decayPeriod) return 0;
            return initialPrice - ((initialPrice * elapsedTime) / decayPeriod);
        } else {
            // if not in auction
            return tulips[tulipNumber].price;
        }
    }

    // ERC721

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory bulbURI = "bafkreiamkokggzkchkosx5jvz6fduzwcn7qugkp7pytmk327sblrtwa4ze";
        string[100] memory tulipURIs = [
            "bafkreiajlq3nd3nc7xu245eqwnoqkh4fz25rdkinw7wkjtqp54xcbxdski",
            "bafkreickj5f3dw6abk4ezj6vvephroacnizpt474jxjffccklci4bm7ulu",
            "bafkreid3ckzlcv3p6zh3o3cwbryno3keqvzyagptnxtoer3awuvyeydz4u",
            "bafkreid43dy6zwtnvwo6skonl4tcechlhnu7rihp2gnvoaydpxn3qw6yva",
            "bafkreicnjnnu6w3crbzxkoa2g625avmnecrh4ptmuvj2q5izygeqhttjny",
            "bafkreiaefcjmmploftqi6ao3dzrpjttnrhay2hqit5pxtzpwkismviwi7e",
            "bafkreid2jrk7rquxayxdfvyg3w447wqssoutoybqeihuunmau4n5ourj4i",
            "bafkreicvpenpqezcdehpcd2snsgj4ysl2la44fzqdolblr6evpps3uujcm",
            "bafkreihuxku32udn2eolrdivdugr2dd5sot2u7cvth3qpsjoqbkllbwkgy",
            "bafkreidumlyzcwbuaajaeeycq6e6y2zcr4jwq2amy35nsh7laphiecbyvi",
            "bafkreigjkkhwb3rtdgvbhjc6aoarrlqmyfe7f4d67fvtxprqns3r5zu6jm",
            "bafkreigmgqiafi4obtmtzzsocylrfcctjtemm3tdvecr3lobo6sqz73o3u",
            "bafkreig5b6rx3mdxwyrtnumyehvuetzrs3dwkxv76wtqhfayammh2hlsve",
            "bafkreicvhumzmjl7bo4uqhngwxfpk6upry4waxm3csk7wgkkyzjejgcwai",
            "bafkreiehn3tovb6wa2nt6nsouavmy6vrijc4z775hk4hjzdn7b5y5lkiya",
            "bafkreid6lxzktumy535tvzedks3acaqzrqirim4migkbxrp5erx5g6mfeu",
            "bafkreihk3mimxxqimwkowm2arpfaewz7m5o76wcvw4acyixhtun673az34",
            "bafkreidrrmeujlvad7oigztu45yeqxwcb6wpo464vwxqst4qo3itwk6ld4",
            "bafkreihl6hl2ufborow5cfiypdtkk2segp3vxfetupapsjnjvzwxlq2che",
            "bafkreidnv2t75e3kx6ugajs23l4736assxkzrggsocz2dvygsjlvhvntza",
            "bafkreih2hhoeruntbfy4ufngko3wbdp4m6gz7otu3hntuvntlflyehkejq",
            "bafkreieiqmc2t62t2pgabenfkeiclb4gsifcwgqvmkcwqc7lkaxm4vqvai",
            "bafkreieqi56ie7iyl4rne2r7ypnvrbcpvxxqp346c74smgd3vypgspdwdi",
            "bafkreidfw4bmdl3rcoehnak43beoeoucbbvtkxlagisvnuchug4foprhpq",
            "bafkreiasg674cri4woi2nmf2be27i24gdegxhc5hgahpygd7vqcrqvz4va",
            "bafkreidn3ocz3m6lzgu7whiooq74mtczbget5fie7dldzwhafdkty5yje4",
            "bafkreieg474qoeg5mykld7dpego4oy4tvjorlgtpjacw3cjrl7oogsfs6a",
            "bafkreiclbj3ujgxgh5i3plai5t24p7g2aavfzahu2gxq4mavena5ojxfsm",
            "bafkreia2vekumcnyswh2w62htqu7vedtksepokixpqn4qwzxhefj2bdniq",
            "bafkreia5456ribmisd555cwt6vzu57oqqkonugozywjuozsoxlo7ffoqxi",
            "bafkreiekctvro262pk4uz67jpqivxtniebqk3gyfqkclw2vqy3m3iocw6e",
            "bafkreigtxjoh4rx62uzlx4t23txqk3owvn3ckhy766mjiwgvy3fny2ozza",
            "bafkreifui4jzaffl74zakibwmt2js2w2qosm7yzgimecwvqpqxpz2psnmu",
            "bafkreif7426cefprxiupxwggnkjbtht3f3uiaeci2qc3irlppuy7kqoenq",
            "bafkreigdimqwjrkoklbfiigbkfpvmrniealdjr2bv52jb72sfbk6aqorqy",
            "bafkreidy2eohxrecrk3si4coolxawlcdmqrvhskhkal4d6bvxjfmds2m24",
            "bafkreie3qfepdl4pkse6uu3iqwfb2fqusfp3qsp2rh7ynvptps3bbnqzdm",
            "bafkreih2hv3vjipj2kibpynrmulnnoxj5737cbeg2bjl42zc3bhcfdzf2u",
            "bafkreiba3227uclzobdglmkvyz4b5da6gp3p3ehtfqznuprlgu3lt7j6nq",
            "bafkreiakbrgj7y2hzb7dhrpub6c6i72i3cp6ygsrof55t5ueb7wtg33bae",
            "bafkreig5x3r3dqllt2ndhxpahni5fjeeo2obq4ffls4hkbi7a2cfqtappi",
            "bafkreihfiplwjo4rdszuhnvjynx7iesij3borjd3rf5onlfgkwlqqjpbou",
            "bafkreicpnd4dysoaov3ra3jxsnoanyfyg3d56ntuzljro77a2bpgbzo6nu",
            "bafkreicdlambpulyaytsiffl2yra55ejhdcchpzlx3trutkoc4tinkiomq",
            "bafkreia57yvsl5esloc7fsn7uiw5q6opkk477f7qgh2sd2mibl66dwgz4m",
            "bafkreigpxggeedsw2y7rd5dqzhhf4qxq3hw3y5qqnmzgmbg5225z32ke6e",
            "bafkreihnezodqrdgshpkx5mkkebiz472y6r3xjnhjtrea75td6jxobf7ha",
            "bafkreiabrwr6bj62rwayp2nvaa7welt24h3rfrsiilj6f6qav4ryjceb4q",
            "bafkreiddvsn24iswrmxt3ceo7pngsvm44qzzknqto2hz4meytsbqw2q2yy",
            "bafkreibu53ggwhoojqkqws3l6nampmzxyczkymw5ozfz6q4t7tpwimha4y",
            "bafkreigwpa25qyx7f23v7t2nbdzywfigwp324dez2kvfrwyibeckl7kmry",
            "bafkreidjlqycv7hkvn6zmsnwbjy7l563pya2fwtnj5mmiqzosjzyuvv7ay",
            "bafkreibphjjkaarzd6kknwwmjtooccup7p3wyuvahmaemcyfjnbdbjci24",
            "bafkreie3unp25d6yx7yvi7bohox2mftpq5rirhl444ylep5ivijovybs5u",
            "bafkreifwh5ih76ed44cy545vyjovzre2esgk7a6m2njeb2qo5ofzus6q34",
            "bafkreie3h3ltvvnokylzyzcpultd7a5ba5ldp4ui4ejlhr7lbucklj4zfu",
            "bafkreiho2ufocna6dgavys6w3hzjudcppni7fnmo5pdes3cn3m7ndiu3b4",
            "bafkreigdwveaxxfl4sfdnyedx4nnnfv7fzspjmmr3j4eozjfv7tjsovwma",
            "bafkreidfixu2x5svom4aivbzbwyszrt7etpy7vm4deiepxgfyzshzn2ypi",
            "bafkreialq7tz66rwqift3hwfhs7mkpjraqp24lk4kk2amlnh535zzkizzy",
            "bafkreieay36cd2bsrn2tipb4zijvkylnfj7dinsaz342gnope7wsrrypjq",
            "bafkreieo6nbwxyahaafswfbe4sahqby3h7ru2hfitzru6iqyxqgch7nrzq",
            "bafkreicsv6fe4ykonns6hxctcjht7bqx5646cbpgbsug4xr6zg5rbthdj4",
            "bafkreihsgdzvuirts3jt3g26lto73qqu4bg7n4qu72dgmkujjkenee7e7a",
            "bafkreigkjwzzhv4cndw3ehsmsbmixzrxxvrpqj2e2yemxnnlwkew5f6gs4",
            "bafkreic5k7u2m4g3yufqpin7ofnb7hgl5vdtmto36l33bw6sjw5hktmo5a",
            "bafkreihxcdefq5k4vomblxkuj75d3b3ixasxvhuobag4whkrwyahfyfidq",
            "bafkreicjwz7p6dpvcqs7ordhzwslabcwuj3y3hehk4pl63jktebjmncjfy",
            "bafkreiakfuy3pabipys3ese6uerduczphy5rdkccguhyhsgyprmn7qz3ke",
            "bafkreialjw6gr3smsmhmrvcdvlsxxvgroyubz7fk2wrvpcrmomx7pdnjoe",
            "bafkreieqchumy7zibxq4mqppdqcdvfawq6ot7dxpbz3v5fue2bwyp5ivsm",
            "bafkreicev7nx7s75yqv2jpttw4rrukztwtr4kubxrs3wv3v4qlkz4nq4uy",
            "bafkreid2itljfobnxpvjfxnsas2fqbly5dyn7tkogvcojjxmb7muqiejta",
            "bafkreibmiuznmb5lk7gsg6376b4z6orbn2b535u6wnimiq5hwe5scref6u",
            "bafkreigxvddcurbaxgubrenqeahen47dktm4om535kaedeqenx7p6zodty",
            "bafkreibtwpwhksgskwqshwuqehwfm772pu7rfxjcxpijpu5ikh2cwvczvq",
            "bafkreic6j5qpgw326wdt6wyaf6efmbzzcw4rl5zfjiken3uxhu4s65hc2e",
            "bafkreibzl22el47bco2hi6wj6zovosteowcdkzifegbg3xncdhd3d3pjnu",
            "bafkreiew3gjv2dgldfzw5kfsginkvqz5rzktd5d4n6a2fnmuqjjk7hhcim",
            "bafkreigbjzymbt3fmlmfta5oror25swedugp2drdvsjb3juahn6e33r6l4",
            "bafkreicpzyumn7fo7negxdwb3anljwf2lqyseqeh7yogcoiyi75kfbtqky",
            "bafkreihsznkosxzsgfkutuuzhh442k7esjduylhda5ausfbautruuazzmm",
            "bafkreidbg24dnbt5to5vl6m5ektfwstwhp2djhsllf5mtciizlgg4lse6y",
            "bafkreidefsxxb5i4nvdblya2mh7h4uo47dwuthb5jqmartgg4svwrvx2xe",
            "bafkreic3qsb5mn22xy46gkg3whiqhvb2lqjmucbquiq27fyf76b7gpf3kq",
            "bafkreiaej6mkm6jjixeqtheomqtbpc4xp3yrtp66vnmcywxler5qlgidw4",
            "bafkreidhgkhkuwp5qqxzdmga7uh52qzeveu53zt4a2ahoauur6gaorf3sq",
            "bafkreibbw4oyakigmurscj3aknyq4tq4b43jjk2wsoszo4672shsog4ssu",
            "bafkreibbhcuhxye2ga3yblf4vmxsq4n3aofxckbyl66axugczb3e6dansu",
            "bafkreibxvv6oipwxyaejwvf4vnftsd6n3bf6ixnvubyus4q5nqud4plcve",
            "bafkreiahwdvpwtzcn2t45rswol5gka42yd2zkn37tn4mscq7mesuwngqyq",
            "bafkreig3mw4xebzxvrj7w5yvkg6o5a55tf2nlenbpruf7oyo3gauqjhtim",
            "bafkreihkaovv3fj2usy3kkzp4hspkisaqymki56pljvqm7yrv2ijta3pbq",
            "bafkreicytcw572hqzksn3zrdut22xo7wjxkf4ovjijokhpkx6vnc3nax7i",
            "bafkreidsfwztyha6q7i5temqm44mlhslcxerjhasj2kdfqhkssl5yfrgnu",
            "bafkreibsvhu3jxeyohswwic7u3xtzwwzbgssqrmmwzyj2fwhnykwpuu7eu",
            "bafkreibexexusac5lrtzmk26f4gc7pg2hzdf4upmd7ks37rteazol76ccy",
            "bafkreiguleybtirhrwdfp3bmmkm7xwq63so3waxgbwyh277uh62dbh55n4",
            "bafkreig7bdme4w26it2vhpdu2ahxbtl2svul5i3h5xhlpbdrxnmrnomqze",
            "bafkreicjehn5krr3lcnyl65eyh3njrfw5atepdzfmjaga44fmangdv5t6q"
        ];
        require(tokenId < 100, "Enter a tokenId from 0 to 99. Only 100 tulips.");
        if (tokenId >= latestNewTulipForSale) {
            return string(abi.encodePacked(_baseURI(), bulbURI));
        } else {
            return string(abi.encodePacked(_baseURI(), tulipURIs[tokenId]));
        }
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256 tokenId
    ) internal override {
        // unlist tulip
        tulips[tokenId].listingTime = 0;
        // emit event
        emit TulipNotForSale(tokenId, msg.sender);
    }

    // ETHERROCK

    function getTulipInfo(uint256 tulipNumber)
        public
        view
        returns (
            address owner,
            uint256 listingTime,
            uint256 price,
            uint256 timesSold
        )
    {
        return (
            ERC721.ownerOf(tulipNumber),
            tulips[tulipNumber].listingTime,
            currentPrice(tulipNumber),
            tulips[tulipNumber].timesSold
        );
    }

    function buyTulip(uint256 tulipNumber) public payable {
        // check sellable
        require(tulips[tulipNumber].listingTime != 0);
        require(tulipNumber < 100, "Enter a tokenId from 0 to 99. Only 100 tulips.");
        // check for sufficient payment
        require(msg.value >= currentPrice(tulipNumber));
        // unlist and update metadata
        tulips[tulipNumber].listingTime = 0;
        tulips[tulipNumber].timesSold++;
        // swap ownership for payment
        if (tulipNumber >= latestNewTulipForSale) {
            // if new, _mint()
            uint256 _latestNewTulipForSale = latestNewTulipForSale;
            // update auction
            if (latestNewTulipForSale < 99) {
                latestNewTulipForSale++;
                tulips[latestNewTulipForSale].listingTime = block.timestamp;
            } else {
                latestNewTulipForSale++;
            }
            // mint and transfer payment
            ERC721._mint(msg.sender, _latestNewTulipForSale);
            payable(feeRecipient).transfer(msg.value);
        } else {
            // if old, _transfer()
            address seller = ERC721.ownerOf(tulipNumber);
            ERC721._transfer(seller, msg.sender, tulipNumber);
            payable(seller).transfer(msg.value);
        }
        // emit event
        emit TulipSold(tulipNumber, msg.sender, msg.value);
    }

    function sellTulip(uint256 tulipNumber, uint256 price) public {
        require(msg.sender == ERC721.ownerOf(tulipNumber));
        require(price > 0);
        tulips[tulipNumber].price = price;
        tulips[tulipNumber].listingTime = block.timestamp;
        // emit event
        emit TulipForSale(tulipNumber, msg.sender, price);
    }

    function dontSellTulip(uint256 tulipNumber) public {
        require(msg.sender == ERC721.ownerOf(tulipNumber));
        tulips[tulipNumber].listingTime = 0;
        // emit event
        emit TulipNotForSale(tulipNumber, msg.sender);
    }

    function giftTulip(uint256 tulipNumber, address receiver) public {
        ERC721.transferFrom(msg.sender, receiver, tulipNumber);
    }
}