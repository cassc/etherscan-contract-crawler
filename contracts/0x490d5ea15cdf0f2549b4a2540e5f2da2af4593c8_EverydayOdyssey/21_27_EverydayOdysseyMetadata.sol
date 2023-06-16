// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {DateTime} from './DateTime.sol';

contract EverydayOdysseyMetadata is DateTime {

    uint16[150] private EverydayNumber = [51,100,153,155,159,169,230,231,232,248,249,250,251,256,259,261,272,273,275,291,293,368,385,396,398,407,422,435,444,450,466,501,505,534,543,580,593,593,628,641,648,662,675,683,698,706,707,714,727,732,733,735,737,744,746,747,748,750,754,763,770,777,778,779,784,789,790,794,799,805,806,808,809,812,813,818,824,831,832,845,849,850,851,852,853,855,858,861,862,866,867,867,873,882,884,894,896,900,904,915,918,930,931,940,944,964,965,966,981,986,987,988,994,999,1005,1014,1025,1030,1031,1032,1038,1039,1043,1045,1046,1044,1048,1053,1062,1065,1066,1067,1069,1071,1072,1073,1078,1096,1101,1105,1106,1107,1109,1112,1119,1141,1180,1186,1207,1209];
    uint8[150] private EverydayMonths = [5,4,6,6,6,7,9,9,9,9,9,9,9,9,9,10,10,10,10,11,11,1,2,2,2,2,3,3,4,4,4,5,6,7,7,8,8,8,10,10,10,11,11,11,12,12,12,12,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,7,7,7,7,8,8,8,8,9,9,9,9,9,9,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,12,12,1,1,1,1,1,1,1,2,2,4,4,5,5];
    uint8[150] private EverydayDays = [3,24,16,18,22,2,1,2,3,19,20,21,22,26,30,2,13,14,16,1,3,18,4,15,16,27,13,27,5,11,25,30,3,2,11,17,30,31,5,18,25,8,22,30,15,21,22,29,11,7,17,19,21,28,30,31,1,3,8,16,23,2,3,4,9,14,15,19,24,20,31,2,3,6,7,12,16,25,26,9,13,14,15,16,17,19,22,25,26,30,31,26,6,15,17,27,29,3,7,18,21,2,10,11,16,6,7,9,24,29,30,1,4,9,15,24,4,9,10,11,17,18,22,24,25,23,27,2,11,14,15,16,18,20,21,22,27,14,19,23,24,25,27,30,6,28,9,15,6,8];
    string[150] private EverydayName = ['A New Beginning','100 out of 100','For The Time Being I Choose To Be Artistically Independent','Its Okay To Cry','The Thread That Unites Us All','Drip Drop','Circles in a Circle','Orange, 1923','I_ll Be Better','The Colors of Fear','The Colors of Anger','The Colors of Sadness ','HALFWAY THERE','It_s About Having Fun','Dessert Sunset','Nighty Nighty','Great Pretender','Brain Mash','Splashes','Green','It Won_t Stop Raining','Pretty Boy David','BUBBLEGUM FANTASY','SPACE MAN IN SPACE','DREAM SEQUENCE','SOMETHING IS COMING','ETHEREUM FOREST','1 HOUR RENDER ','Tripping in Space ','Your Comfort Zone Will Kill You ','HONDURAN GOTHIC ','BREAKING BAD  ','INTERGALACTIC VIEW ','DEVOTE','TRIPPING IN SPACE','FOLLOWING MY DREAM ','E-GIRL ','E-ND ','HAPPY AND SAD ','MEMORY LANE  ','A million miles away  ','VOID ','COKE MOUNTAIN ','COVID ROUND 3  ','EVENT-0001  2','GRATEFUL ','DAY 707 ','WITH LOVE','CRYSTAL WHITE ','MOONLIGHT','RED GIANT  ','ANCIENT BITCOIN ','NFT REVOLUTION 2.0 ','ETHEREUM GODS ','KEEP BELIEVING ','META META META ','TO THE MILKY WAY  ','BEGINNING OF SOMETHING...  ','FIRST LIVESTREAM ','GOD-DESS ','WHERE IS MY MIND ','GRIM REAPER ','DIGITAL SIN ','ViRUS ','ETERNAL SLUMBER ','SO CLOSE YET SO FAR ','WAKE UP ','MY FIRST HUNGOVER ','THE _XXX_ SQUAD ','THE MONOLITH ','BIG SPHERE ','PYRAMIDS ','THE BIG EYE ','HEAD DISTORTION ','ANGST ','LOSING IT v4 ','LOST CHILDHOOD MEMORIES V2  ','OU WONT KNOW UNLESS YOU TRY v3 ','TWITTER BOTS ','PTSD  ','MY CORE ','DAY 850','CANT REST MUST WORK ','CHERRY BOMB v2 ','so close ','IN PIECES ','i WILL NOT FUCK UP ','ON _ ON ','BIG BOTHER IS WATCHING ','ROTTING AWAY ','2 NOSTALGIA','MY HEAD KEE SPINNING','TRYING TO FIND PEACE ','DESTRUCTION II ','DEAD ASTRO ','MAYBE I FORGOT HOW TO BE HUMAN ','EMOTIONAL MESS ucale ','THE LAST 100 DAYS ','MY MUSE','EMBRACE THE MADNESS ','KEEP REACTING ','G0D ','BLUE SCREEN OF DEATH','ENJOY BEING DIFFERENT ','CLOWN EMOJI...  ','JAILBREAK ','FLASHBACK EP1 ','FLASHBACK 03','AE 1000 X ','SWEET DEATH ','AWOKEN ','RESTiNG ','SO CLOSE ','JUST ONE MORE DAY ','WE CAN DO BETTER ','not feeling it ','new age portrait ','SLOWLY DECOMPOSING','DIGITAL PARANOIA','YOU ARE MY CORE  ','sleepy day ','Fake Skies ','MIXED BAG OF EMOTIONS ','CANT CLOSE MY EYES ','FLOWER EXPLOSION ','alll we need is a link cable','WHO AM I ','MIGRAINE ','ITS THAT CHRISTMAS VIBE ','ONE OF THOSE DAYS HUH ','WATCHING ME DROWN ','BIG PICTURE ','F_CKED UP SLEEPING SCHEDULE ','SOMETIMES I WONDER IF WE ARE EVEN HUMAN ','NOBODY GETS ME LIKE YOU ','WOKE UP AT 3PM I FEEL DEAD ','ADAMs CREATION ','old me  ','aint for the weak','CONTENT FARM ','froggy temple','MONEY MONEY MONEY ','stop overthinking ','last bus ride ','THE DARKEST ODDYSEY ','KEEP DREAMING ','GROWING FRUSTRATION ','LETS WAIT HERE TILL WE DIE','Pixelated Dreams ','The Last Spoonful of a Vanishing Reality'];
    string[150] private EverydayDate = ['5/3/20','4/24/20','6/16/20','6/18/20','6/22/20','7/2/22','9/1/20','9/2/20','9/3/20','9/19/20','9/20/20','9/21/20','9/22/20','9/26/20','9/30/20','10/2/20','10/13/20','10/14/20','10/16/20','11/1/20','11/3/20','1/18/21','2/4/21','2/15/21','2/16/21','2/27/21','3/13/21','3/27/21','4/5/21','4/11/21','4/25/21','5/30/21','6/3/21','7/2/21','7/11/21','8/17/21','8/30/21','8/31/21','10/5/21','10/18/21','10/25/21','11/8/21','11/22/21','11/30/21','12/15/21','12/21/21','12/22/21','12/29/21','1/11/22','1/7/22','1/17/22','1/19/22','1/21/22','1/28/22','1/30/22','1/31/22','2/1/22','2/3/22','2/8/22','2/16/22','2/23/22','3/2/22','3/3/22','3/4/22','3/9/22','3/14/22','3/15/22','3/19/22','3/24/22','3/20/22','3/31/22','4/2/22','4/3/22','4/6/22','4/7/22','4/12/22','4/16/22','4/25/22','4/26/22','5/9/22','5/13/22','5/14/22','5/15/22','5/16/22','5/17/22','5/19/22','5/22/22','5/25/22','5/26/22','5/30/22','5/31/22','6/26/22','6/6/22','6/15/22','6/17/22','6/27/22','6/29/22','7/3/22','7/7/22','7/18/22','7/21/22','8/2/22','8/10/22','8/11/22','8/16/22','9/6/22','9/7/22','9/9/22','9/24/22','9/29/22','9/30/22','10/1/22','10/4/22','10/9/22','10/15/22','10/24/22','11/4/22','11/9/22','11/10/22','11/11/22','11/17/22','11/18/22','11/22/22','11/24/22','11/25/22','11/23/22','11/27/22','12/2/22','12/11/22','12/14/22','12/15/22','12/16/22','12/18/22','12/20/22','12/21/22','12/22/22','12/27/22','1/14/23','1/19/23','1/23/23','1/24/23','1/25/23','1/27/23','1/30/23','2/6/23','2/28/23','4/9/23','4/15/23','5/6/23','5/8/23'];
    string[150] private EverydayMiniseries = ['Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','Abstract','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','Animation','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','Animation','Animation','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','Animation','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','Animation','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D','3D'];

    mapping (uint256 => bool) public animationMapping;

    constructor() {
        animationMapping[49] = true;
        animationMapping[90] = true;
        animationMapping[91] = true;
        animationMapping[102] = true;
        animationMapping[118] = true;
    }

    function getEverydayNumber(uint256 index) public view returns (uint16) {
        return EverydayNumber[index];
    }

    function getEverydayMonths(uint256 index) public view returns (uint8) {
        return EverydayMonths[index];
    }

    function getEverydayDays(uint256 index) public view returns (uint8) {
        return EverydayDays[index];
    }
    
    function getEverydayName(uint256 index) public view returns (string memory) {
        return EverydayName[index];
    }
    
    function getEverydayDate(uint256 index) public view returns (string memory) {
        return EverydayDate[index];
    }
    
    function getEverydayMiniseries(uint256 index) public view returns (string memory) {
        return EverydayMiniseries[index];
    }
    
    function generateTokenURI(uint256 tokenId, string memory baseURI, string memory baseAnimationURI) public view returns (string memory uri) {
        string memory imgUrl = 'https://static.wild.xyz/tokens/unrevealed/assets/unrevealed.webp';

        string memory stringTokenId = Strings.toString(tokenId);
        string memory attributesStr = '';
        string memory animationUrl = '';
        if (bytes(baseURI).length > 0) {
            string memory fileExt = '.png';

            if (animationMapping[tokenId] == true) {
                imgUrl = string(abi.encodePacked(baseURI, stringTokenId, fileExt));
                fileExt = '.mp4';
                animationUrl = string(abi.encodePacked(baseURI, stringTokenId, fileExt));
            }
            else if (DateTime.getMonth(block.timestamp) == getEverydayMonths(tokenId) && DateTime.getDay(block.timestamp) == getEverydayDays(tokenId)) {
                if (tokenId <= 20) {
                    animationUrl = string(abi.encodePacked(baseURI, stringTokenId, '.mp4'));
                } else {
                    animationUrl = string(abi.encodePacked(baseAnimationURI, stringTokenId));
                }
                imgUrl = string(abi.encodePacked(baseURI, stringTokenId, fileExt));
            }
            else {
                imgUrl = string(abi.encodePacked(baseURI, stringTokenId, fileExt));
            }

            {
                string memory miniseries = getEverydayMiniseries(tokenId);
                string memory date = getEverydayDate(tokenId);
                string memory everydayname = getEverydayName(tokenId);
                string memory everydayNumber = Strings.toString(getEverydayNumber(tokenId));
                attributesStr = string(abi.encodePacked(',"attributes":[{"trait_type":"Name","value":"', everydayname, '"}, {"trait_type": "Miniseries", "value":"', miniseries, '"}, {"trait_type": "Date", "value":"', date, '"}, {"trait_type": "Number", "value":"', everydayNumber, '"}]'));
            }
        }
        
        string memory json;
        {
            string memory name = string(abi.encodePacked('Everday Odyssey #', stringTokenId));
            string memory description = 'Everyday Odyssey is a collection of curated image outputs from stupidgiant&#39;s daily sketch practice. stupidgiant has sorted through his vast archive, and selected this tight collection of his favorite everydays that draw particular attention to the most memorable moments along his artistic journey. Amusing experiences, major life events, and defining changes are represented in the collection, which amounts to a contemporary portrait of the artist and his development in today&#39;s Web3 creative culture. In addition to a still image, rendered output, each collectible token comes with a special wireframe view, which showcases the foundational structure of each artwork. Combining the results of diligent practice with imaging tools like Blender and photoshop, the artist&#39;s development of craft takes central focus. Increased complexity and refinement become apparent over time, with the incremental steps in stupidgiant&#39;s evolving style coming into clear view. By exploring the various metadata associated with each token, the collector becomes a co-conspirator in stupidgiant&#39;s ever-changing practice. He invites the viewer to spelunk through all of the microdetails of the collection, unearthing the subtle nuances that distinguish each work.';
            string memory externalUrl = string.concat('https://wild.xyz/stupidgiant/everyday-odyssey/', stringTokenId);
            
            json = Base64.encode(bytes(abi.encodePacked('{"name":"', name, '", "description": "', description, '", "image": "', imgUrl, '", "animation_url": "', animationUrl, '", "external_url": "', externalUrl, '"', attributesStr, '}')));
        }
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}