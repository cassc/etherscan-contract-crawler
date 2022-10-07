// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                        ╓                                          //
//                             └⌐        ▓▌  ,▓¬        ,▄▓                          //
//                ²▄,        ╫⌐ ▓ ▌    ╒J▓⌐ ▓▓¬    ╓▄▄▓▓▓▓▀         ,▄▄▓▀            //
//                 ▐▓▌ ▓     ▓▄▓▓ ▓⌐   j▓▓ ▓▓▌ ▄▓▓▓▓▓▓▓▀▐▄▌▓▓▓▓▓▓▓▓▓▓▓▓              //
//                 ▐▓▓ ▓    ▓▓▓▓▓ ▓▓   ▓▓▓ ▓▓▌▐▓▀▀▀▓▓▓ ▐▓▓▓▓▓█▀▀╙¬¬└▀▓               //
//                 ▓▓▓▓▓   ▓▓▓▓▓ ▐▓▓  ▐▓▓▌ ▓▓▌▐▌   j▓▓ ▓▓▓▓▀                         //
//                ▐▓▓▓▓▓   ▓▓▓▓▓ ▓▓▓  ▐▓▓▓ ▓▓▌     ]▓▓ ▓▓▓▌    ▄▄                    //
//                 ▓▓▓▓▓  ▄▓▓▓▓▓ ╫▓▓▓▓▓▓▓▌ ▓▓▌     ▓▓▓ ▐▓▓µ ,▓▓▓                     //
//                  ▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▀▓▓▓▌ ▓▓▌    ▄▓▓▓ ▐▓▓▓▓█▀▀Γ                     //
//                  ▀▓▓▓▓▓▓▓▓▓▓  ▓▓▓▄ ▐▓▓▌ ▓▓▌   ▀▓▓▓▌ ╫▓▓▀                          //
//                   ▓▓▓▓▓▓▓█▓▓  ▀▓▓b ▐▓▓▓ ▓▓▌    ▓▓▓  ▓▓▓       ╓▌                  //
//                   ▐▓▓▌╙¬¬ j▓▌  ▓▓   ▓▓▓ ▓▓▄   ▐▓▓  ▐▓▓▓   ▓▓▓▓▓                   //
//                  ,▓▓█`   ,▓█` ▄▓▀  ▄▓▓▀▄▓▀   ╓▓█¬ ▄▓▓▓▀ ,▓▓▓▓▓▀                   //
//                 ▓▓▓     ▓▓  ▄▓╙  ▄▓▓`▄▓▀   ╒▓▓  ╓▓▓▓▀  ▓▓▓▓▓▀                     //
//                 ▀▓▓▄    ▀▓▄ ╙▓▄  ╙█▓▄╙▓▓µ   ▀▓▄  ▀▓▓▌⌐ ▀▓▓▓▓▌                     //
//                  ▐▓█▌    ▀▓  ▐▓    ▓▓ ╫▓▀   ▐▓¬  ▐▓▓▓▓▓▓▓▓▓▓▓                     //
//                   ▓ ▀     ▀  ▐     ▀▌ ▓▌    ▓¬   ▀▀¬ ▐▓▓▓█▀▀                      //
//                   ▓                ▐▓ ▓⌐   ▐▓         ▓\                          //
//                   ▐                 ▓ ▓    ▐¬        '▌                           //
//                                   ▓∩.         ]▄                                  //
//       ▓µ             ╓▌         ▄▓▓▓ ▓       ▄▐▓              ╓▄Æ            µ    //
//       ▓▓▓           ▓▓       ,▄▓▓▓▓▓ ▓▓     ▄▓▓▌  ,▄▄▄▄▄▄▄▓▓▓▓▓▓         ,▄▓▓     //
//     ▄▓▓▓▓▄          ▓▓    ▄▓▓▓▓▓▓▓▓  ▓▓▌    ▓▓▓ ]▓▓▓███▓▓▓▓▓█▓▓▓ ▄▓▓▓▓▓▓▓▓▓▓      //
//     █▀▓▓▓           ▓▓µ  ▓▓▓▓▀▀╙¬   ▐▓▓▓    ▓▓▓ ▓▓█    ▐▓▓▓  ▓▓ ▓▓▓▓▓█▀▀▀▀`       //
//      ╓▓▓▓           ▓▓▌ ▓▓▓▀     ▄▓⌐j▓▓▓▄▄╓▄▓▓▌ ▓      ▓▓▓b  ` ▐▓▓▓▓,             //
//     ▄▓▓▓▓          ]▓▓▌ ▓▓▓   ▓▓▓▓▓µ ▓▓▓▓▓▓▓▓▓▌       .▓▓▓    , ▀▓▓▓▓▓▓▄,         //
//    ╚`  ▓▓▌       ╫▄▐▓▓ ╫▓▓▓▌     ▓▓▌ ▓▓▓█▀╙▀▓▓▓       j▓▓▓    ▐▓   ▀▀▓▓▓▓▓▄       //
//       j▓▓▌       ▓▌.▓▓ ▐▓▓▓▓▓   ▐▓▓▓ ▐▓▓    ╫▓▓        ▓▓▌    ▐▓▓     ▓▓▓▓▓       //
//        ▓▓▓       ▓▓ ▓▓ ▐▓▓▓▓▓µ  └▓▓▓ ▐▓▓    ▐▓▓µ       ▓▓▓    ▐▓▓     ▓▓▓▓▓       //
//       ▓▓▓╙      ▄▓,▓▓▀,▓▓▓▓▓█   ▓▓▓▀,▓▓▀   ,▓▓█       ▄▓▓"   ,▓▓▀    ╓▓▓▓▓▀       //
//     ▄▓▓▀      ╓▓▀▄▓▀,▓▓▓▓▓█¬  ▄▓▓▀.▓▓▀    ▓▓█¬      ▄▓▓▀    ▓▓▀    ,▓▓▓▓▀         //
//     ╙▀▓▓▄     ╙╙▀▓▀█▌▀▀▓▓▓▓▄ç ▀▀▓▓▄▀▀▓▄  ¬▀▀▓▄µ     ╙▀▓▓▄  ¬▀▀▓▄   ╙▀█▓▓▓▄        //
//       ▐▓▓▄     ▄▓▓b▐▓▌ ▐▓▓▓▓▓▓▓▓▓▓▓▌ ▓▓▌    ▓▓▓       j▓▓∩   ,▓▓▓▓     ▓▓▓▌       //
//       └▓▓▓▓▓▓▓▓▓█▀ ▐▓▌   █▓▓▓▓▓▓▓▓▓▌ ▓▓▓    ▓▓▓        ▓▓⌐    └▀▓▓▓▓▓▓▓▓▓▓        //
//        ▓▓▓▓█▀▀¬    j▓▌      ¬    ▓▓▓ ▓▓▓    ▀▓▓        ▓▓        ╙▓▓▓▓▓▓¬         //
//        ▓▓▀          ▓▌           ▓▓▀ ╫▓▓     ▓▌       j▓▌          ▓▓▓█▀          //
//       .▓            ▓            ▓   ╫▓      ▓▌       ▓▀           ╫▓             //
//       Å             ▀            ▓   ▓       ▓       ▓▀            ▓¬             //
//                                              ▌      ▐▀                            //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////
///
/// @title:  a quantum entanglement
/// @author: whitelights.eth | @iamwhitelights
/// @author: manifold.xyz
///
/// This extension mints and controls a diptych series perpetually in a state of quantum entanglement
/// enforced by the blockchain. Each generative piece behaves as an entangled particle, where mining
/// a block on the Ethereum blockchain causes its wave function to collapse, resulting in each
/// artwork revealing itself. The outcome is random, with each possibility having a
/// probability of 50% before the block is mined. Still, the results are always anti-correlated.
/// Between blocks, their state is considered unknown, a seemingly paradoxical phenomenon.
///
/// The hope is to humanize Quantum Mechanics by drawing a link between Schrödinger's
/// paradox and the human condition of oscillating between happiness and sadness. I never know how
/// to describe my feelings until I’m asked, begging the follow-up, how does one illustrate the
/// limbo state before introspection? All possibilities seem equal to me.
///
/// These artworks are on-chain and have no dependencies besides Ethereum and a browser. The HTML,
/// JS, and SVGs have no 3rd party dependencies, are supported in all modern browsers, and do not
/// require an active internet connection.
///

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract AQuantumEntanglement is AdminControl, ICreatorExtensionTokenURI {
    using Strings for uint256;

    address private _creator;
    uint256 private _tokenId1;
    uint256 private _tokenId2;
    string public script;
    string public description;

    constructor(address creator) {
      _creator = creator;
    }

    function initialize() external adminRequired {
      script = "</script><style>body,html{display:flex;flex-direction:column;justify-content:center;height:100%;width:100%;margin:0}canvas{max-width:100%;max-height:100%;object-fit:contain;padding:40px;box-sizing:border-box}</style></head><body><script>let e=seed==='1';const o=e?'okay':'sad';var r=document.createElement('canvas');document.body.appendChild(r);r.height=r.width=2020;let d=r.getContext('2d');let f='source-over';function t(e){d.globalCompositeOperation=f;var n=101;var t=r.height/n;for(var a=0;a<n*2;a++){d.beginPath();d.strokeStyle=a%2?'white':'black';d.lineWidth=t;d.moveTo(a*t+t/2-r.width,0);d.lineTo(0+a*t+t/2,r.height);d.stroke()}const c=400*r.height/2020;d.globalCompositeOperation='difference';d.fillStyle='white';d.textBaseline='middle';d.font=`italic ${c}px sans-serif`;d.textAlign='left';const i=d.measureText('i am '+o).width;if(f==='difference'){d.fillText(parseInt(e)%6!==1&&f==='difference'?'i am '+(o==='sad'?'okay':'sad'):'i am '+o,(r.width-i)/2,r.height/2)}else{d.fillText('i am '+o,(r.width-i)/2,r.height/2)}}const a=60;let c=0;let n=0;function i(e){window.requestAnimationFrame(i);if(e-c<1e3/a)return;var n=d.getImageData(0,0,r.width,r.height);t(e);c=e}document.addEventListener('DOMContentLoaded',()=>{i(0);r.addEventListener('click',()=>{f=f==='difference'?'source-over':'difference'})});</script></body></html>";
      description =  'i exist in the interference. pause to introspect, i collapse the emotional wave function. somewhere between the blocks, there lies the truth. somewhere in the ether, we are not always opposed.\\n\\n--------------------\\n\\nthis blockchain performance exhibits a system of emotional entanglement between two separate generative artworks, enforced by smart contract. both the artwork and renderer live on chain as one without external dependencies.\\n\\n--------------------\\n\\ndiptych\\n\\nhtml,js,solidity,performance\\n\\nwhite lights (b. 1993) 2022\\n\\n--------------------\\n\\ntrigger warning: flashing lights upon interaction';
      _tokenId1 = IERC721CreatorCore(_creator).mintExtension(
        msg.sender
      );
      _tokenId2 = IERC721CreatorCore(_creator).mintExtension(
        msg.sender
      );
    }

    function setScript(string memory newScript) public adminRequired {
      script = newScript;
    }

    function setDescription(string memory newDescription) public adminRequired {
      description = newDescription;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
      return interfaceId == type(ICreatorExtensionTokenURI).interfaceId
        || AdminControl.supportsInterface(interfaceId)
        || super.supportsInterface(interfaceId);
    }

    function getAnimationURL(bool quantumStateBool, string memory restOfScript) private pure returns (string memory) {
      return string(
        abi.encodePacked(
          "data:text/html;base64,",
          Base64.encode(abi.encodePacked(
            "<html><head><meta charset='utf-8'><script type='application/javascript'>const seed='",
            quantumStateBool ? "1" : "0",
            "'",
            restOfScript
          ))
         )
      );
    }

    function getPreviewImage(bool quantumStateBool) private pure returns (string memory) {
      return string(
        abi.encodePacked(
          "data:image/svg+xml;base64,",
          Base64.encode(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='2020' height='2020'><style>text {font: italic 400px sans-serif; mix-blend-mode: difference;}</style><defs><pattern id='str' patternUnits='userSpaceOnUse' width='20' height='20' patternTransform='rotate(125)'><rect x='0' y='0' width='20' height='20' fill='white'></rect><line x1='0' y='0' x2='0' y2='20' stroke='#000000' stroke-width='20'></line></pattern></defs><rect width='100%' height='100%' fill='url(#str)' opacity='1'></rect><rect x='0' y='0' width='2020' height='2020' stroke='red' fill='transparent'></rect><text class='text' x='50%' y='50%' dominant-baseline='middle' fill='white' text-anchor='middle'>",
            quantumStateBool ? "i am okay" : "i am sad",
            "</text></svg>"
          ))
        )
      );
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
      require(creator == _creator, "Invalid token");
      require((tokenId == _tokenId1 || tokenId == _tokenId2), "Invalid token");

      bool quantumStateBool = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 2 == 0 ? false : true;

      if (tokenId == 1) {
        quantumStateBool = !quantumStateBool;
      }

      // updateable description would be nice
      return string(abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(abi.encodePacked(
          '{"name":"a quantum entanglement #',
          tokenId.toString(),
          '","created_by":"white lights","description":"',
          description,
          '","animation_url":"',
          getAnimationURL(quantumStateBool, script),
          '","image":"',
          getPreviewImage(quantumStateBool),
          '","attributes":[{"trait_type":"Spin","value":"',
            quantumStateBool ? 'Up' : 'Down',
          '"}]',
          '}'
        ))
      ));
    }
}