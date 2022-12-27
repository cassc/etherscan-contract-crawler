// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
友人の死で命が尽き、
過ぎ去った時代の記憶
彼らの糸は昔の生地を織りました。
 **/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BurntSouls is ERC721, Ownable {
    using Strings for uint256;

    /**
友人の死で命が尽き、
日の出と日の入り、明るい昼と暗い夜
何度も何度も円を描き、この人生に文脈を与えました。
刻一刻と、彼らの人生は毎日生きていました。
**/

    address public supernova;
    address public BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    string public baseURI;

    /**
友人の死で命が尽き、
人生は親愛なる人の旅に感動し、
笑いあり、涙あり、希望あり、恐れあり、人生は終わった
記憶は、私自身の生活の中で、その精神を生き生きとさせます。
**/

    constructor() ERC721("Burnt Souls", "BRNSM") {
        baseURI = "https://burnt-souls-metadata.vercel.app/api/";
    }

    /**
友人の死で命が尽き、
将来の瞬間の喪失、それはあり得ない、
共有された瞬間に感謝し、私を養い、
何気ない信念の中で生きた瞬間は、決して終わらないだろう.
**/

    function resurect(address to, uint256 tokenId) external {
        require(msg.sender == supernova, "Only Supernova can resurect");
        _mint(to, tokenId);
    }

    /**
私の一部が終わった 友人の死で
彼らが地上の面からいなくなっても、彼らの精神は舞い上がり、
サマーランド、天国、または別の人生で、再び更新する
どこかはわかりませんが、彼らの愛は私と共にあります。
この人生で、私たちは友人であり、分かち合いました。
**/

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        require(to == BURN_ADDRESS || from == address(0), "Burnt Souls cannot be transferred");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
友達がいなくて寂しいけど、いつも近くにいるよ
私、あなたの中、そして時間を割いて聞いてくれたすべての人、
大切なこの人生の音楽、今は静かな人生、
生き残った人々の記憶の中でのみ生きています。
**/

    function setSupernova(address _supernova) external onlyOwner {
        supernova = _supernova;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
}