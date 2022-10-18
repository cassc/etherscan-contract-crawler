// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title: 一人暮らしの女の子の部屋
/// @author: ぴぴぴ (@pipipipikyomu)
/// @dev: 一人暮らしの女の子の部屋を再現したホテルを作りましょう。こちらが一人暮らしの女の子の部屋です。

/*
[email protected]!  .W,.ga    .#dSldNJ.    .HN.   ?THMMMHHHHHHMMMHMWfWMMHNWH
HMMMMMMHHHHHHMMHHMD`    MOZwdD     .#OdBQM`   .MuXMMMM|  -.?YMMMHHHHMMMNfVWMMNWH
[email protected]#!      .5M"`  ......?5     ` MstZUVQ#`  _`    TMMHHHMMNkfVfWffM
[email protected]$    ...JgMMMMMMMMMMMMMMMMMMMNNggMW""=  ..      .MMMMHHHMMMNQQQQH
[email protected]@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected],~. ` ` MMMHHMHHHMMMHHHHH
HHHHHHHM#[email protected]@[email protected]@@@@@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected]@@[email protected]@HMMMa., (MHMHHHHHHHMMMHHHH
[email protected]@@[email protected]@[email protected]@@@@[email protected]@@@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@@@@MMMMHMMHHHHHHHMMMHHH
[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@MMHMHHHHHHHHMMNHH
[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@@@[email protected]@@MMMMHHHHHHHHMMMM
HHHH#[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@@M#[email protected]
HHHH#[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@@[email protected]@[email protected]@@@@[email protected]@[email protected]@[email protected]@@[email protected]@@MMMHMMMMHHHHMM
[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@MMMNudMHHHHMM
HHHHM#[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@MMQJrMMHHHHM
[email protected]@@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@@@HMMM#rMMHHHHM
HHMMM#[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@@@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@MMMMMNMMM#MMHHHHHH
[email protected]@@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected]@MMHHHHHHHHH
[email protected]@@[email protected]@@[email protected]@@[email protected]@[email protected]@@@@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@HM#[email protected]@[email protected]@@@[email protected]@@[email protected]@HH
[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@@[email protected]@[email protected]@@[email protected]
[email protected]@@@[email protected]@@@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@M'[email protected]@[email protected]@[email protected]@@@@MMHHHHHHHH
[email protected]@[email protected]@[email protected]@@MNNMMMMMMY""""7!?777"!.MMMMMMMh.,[email protected]@[email protected]@[email protected]@[email protected]@HHHH
[email protected]@@@MNMMMMMMMMMNMM,```````````` [email protected]
[email protected]#"(dMNWUHdMN ```````````[email protected]
[email protected]"``.MMHWXWXWMM|``.``.`.``.MMMHXWkXNNM-` [email protected]
MMHWHMMHHHMMMMMMb``` M#WHWWWWWMM]````.```.`.#MHXWSHuWMd]```[email protected]@HM\`([email protected]
MNHMMMMHHHMMMMMMM-``.M#HXWWWHdMM:``.```````JNMSWXXWubMM]``[email protected]@@M#`[email protected]@HHH
[email protected]@MM]``,M#Uw0UUwMMF```````.```(NHkZXZwZXMM]`[email protected]@[email protected]
[email protected]@[email protected]@@MF``[email protected]``.``.```.``.M#XOttwXqM#_([email protected]@MMMMMMNMHHMMHHHHHH
[email protected]@MF`([email protected] ````.```````.(WNmXzQdMD_,~`[email protected]@@@MMHHHHHH
[email protected]@MF`,MB$7""""~.``.````.``.````._TMM5!(([email protected]@@[email protected]@HH
[email protected]@HM]``-~```````````.((J.,``.````````` <!``!([email protected]@[email protected]@MMHHHHHH
[email protected]@MNJ.`````.``.````.#KwM#^``````````````[email protected]@[email protected]@HMMHHHHHM
[email protected]@@@@MMN,.```````.``.MgD_`````.```.`` [email protected]@[email protected]@@[email protected]
[email protected]@[email protected]@[email protected]```.````````.```....J#[email protected]@[email protected]@[email protected]@[email protected]@MMHHHHMH
[email protected]@[email protected]@@@[email protected]"`    [email protected]@@[email protected]@[email protected]
[email protected]@@[email protected]@[email protected]@@[email protected]@@@HMM'  TNM'          [email protected]@[email protected]@@MMHHHHH
[email protected]@@[email protected]@[email protected]@@HMNMMD     MMgNJ ` `  .JN([email protected]@[email protected]@[email protected]
[email protected]@@[email protected]@[email protected]@@[email protected]@HNMMMMJ] .M#MMM#,M]   `[email protected]@[email protected]@HH
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HitoriGurashiNoOnnaNoHeya is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string akaiKusuri = "ar://uNH1hsnIPnKKU71MZbZmP0BclCEjIT4cs-gUXPZ9sIc";
    string aoiKusuri = "ar://LDr--En4hDj2vSZHUiccscN9epqQMpzUrodFP_aXwpE";

    constructor() ERC721("HitoriGurashi", "HITORIONNA") {
    }

    /**
     * @notice 忘れるな・・・。私が見せるのは真実だ。純粋な真実だ
     */
    function AkaiKusuriWoNomu(address to) public {
        require(totalSupply() < 1, "Shinjitsu wo miru ha hitori dake");
        _safeMint(to, totalSupply()+1);
    }

    /**
     * @notice 夢から起きられなくなったとしたら、どうやって夢と現実の世界の区別をつける？
     */
    function AoiKusuriWoNomu() public {
        require(totalSupply() <= 100, "Yume No Kuni Ha Teiin Over");
        _safeMint(msg.sender, totalSupply()+1);
    }

    /**
     * @notice 赤い薬と青い薬はなんですか？
     */
    function KusuriHaNani () external pure returns(string memory){
        return (unicode"青い薬を飲めば、お話は終わる。君はベッドで目を覚ます。好きなようにすればいい。赤い薬を飲めば、君は不思議の国にとどまり、私がウサギの穴の奥底を見せてあげよう");
    }

    /**
     * @notice なぜ一人暮らしの女の子の部屋なのに汚いのですか？
     */
    function NazeObeyaNano () external pure returns(string memory){
        return (unicode"一体いつから、女の子の一人暮らしの部屋がキレイだと錯覚していた？");
    }


    /**
     * @notice ピンクの華やかな部屋が一人暮らしの女の子の部屋では？
     */
    function PinkNoHeyaWoKudasai () external pure returns(string memory){
        return (unicode"夢から覚めなさい");
    }

    /**
     * @notice なぜ赤い薬は一つだけなのですか？
     */
    function NazeAkaiKusuriHaHitotsu () external pure returns(string memory){
        return (unicode"真実は常にひとつ");
    }

    /**
     * @notice Hey Siri. 今日の天気は？
     */
    function HeySiriKyounoTenkiHa () external pure returns(string memory){
        return (unicode"すみません。わかりません");
    }


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (tokenId == 1) {
            return akaiKusuri;
        }
        return aoiKusuri;
    }

    function setRedURI(string memory uri) onlyOwner public {
        akaiKusuri = uri;
    }

    function setBlueURI(string memory uri) onlyOwner public {
        aoiKusuri = uri;
    }

}