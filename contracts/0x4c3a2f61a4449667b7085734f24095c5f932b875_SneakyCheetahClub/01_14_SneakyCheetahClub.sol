//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// File contracts/SneakyCheetahClub.sol
/*

  /$$$$$$  /$$   /$$ /$$$$$$$$  /$$$$$$  /$$   /$$ /$$     /$$        /$$$$$$  /$$   /$$ /$$$$$$$$ /$$$$$$$$ /$$$$$$$$ /$$$$$$  /$$   /$$        /$$$$$$  /$$       /$$   /$$ /$$$$$$$ 
 /$$__  $$| $$$ | $$| $$_____/ /$$__  $$| $$  /$$/|  $$   /$$/       /$$__  $$| $$  | $$| $$_____/| $$_____/|__  $$__//$$__  $$| $$  | $$       /$$__  $$| $$      | $$  | $$| $$__  $$
| $$  \__/| $$$$| $$| $$      | $$  \ $$| $$ /$$/  \  $$ /$$/       | $$  \__/| $$  | $$| $$      | $$         | $$  | $$  \ $$| $$  | $$      | $$  \__/| $$      | $$  | $$| $$  \ $$
|  $$$$$$ | $$ $$ $$| $$$$$   | $$$$$$$$| $$$$$/    \  $$$$/        | $$      | $$$$$$$$| $$$$$   | $$$$$      | $$  | $$$$$$$$| $$$$$$$$      | $$      | $$      | $$  | $$| $$$$$$$ 
 \____  $$| $$  $$$$| $$__/   | $$__  $$| $$  $$     \  $$/         | $$      | $$__  $$| $$__/   | $$__/      | $$  | $$__  $$| $$__  $$      | $$      | $$      | $$  | $$| $$__  $$
 /$$  \ $$| $$\  $$$| $$      | $$  | $$| $$\  $$     | $$          | $$    $$| $$  | $$| $$      | $$         | $$  | $$  | $$| $$  | $$      | $$    $$| $$      | $$  | $$| $$  \ $$
|  $$$$$$/| $$ \  $$| $$$$$$$$| $$  | $$| $$ \  $$    | $$          |  $$$$$$/| $$  | $$| $$$$$$$$| $$$$$$$$   | $$  | $$  | $$| $$  | $$      |  $$$$$$/| $$$$$$$$|  $$$$$$/| $$$$$$$/
 \______/ |__/  \__/|________/|__/  |__/|__/  \__/    |__/           \______/ |__/  |__/|________/|________/   |__/  |__/  |__/|__/  |__/       \______/ |________/ \______/ |_______/ 
                                                                                                                                                                                                                                                                                                          
*/
contract SneakyCheetahClub is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string public CHEETAH_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN CHEETAHS ARE ALL SOLD OUT

    string public baseTokenURI;

    uint256 public cheetahPrice = 0.03 ether; // 0.03 ETH

    uint256 public constant maxCheetahPurchase = 6; //MAX purchase limit is 5 per txn

    uint256 public constant MAX_CHEETAHS = 3031; //MAX total cheetahs is 3030

    bool public saleIsActive = false;

    uint256 public cheetahReserve = 31; //MAX reserve supply is 30 for giveaways and promotions

    address a1 = 0xD47d88d7F9D4164C2627048a1470DA8199c4b5d4; //Amanda
    address a2 = 0x3b2426aa615A17D9D15281131B89fDc4CcEA868F; //Jeremy
    address a3 = 0xe05AdCB63a66E6e590961133694A382936C85d9d; //Eleven

    constructor() ERC721("Sneaky Cheetah Club", "CHEETAHS") {}

    //Team reserve for promotions and giveaways
    function reserveCheetahs(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        require(_reserveAmount < cheetahReserve, "Reservation amount reached");
        uint256 supply = totalSupply();
        require(
            supply + _reserveAmount < MAX_CHEETAHS,
            "Not enough reserve left for the team"
        );
        for (uint256 i = 1; i <= _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        cheetahReserve = cheetahReserve.sub(_reserveAmount);
    }

    function adoptSneakyCheetah(uint256 _count) public payable {
        if (msg.sender != owner()) {
            require(saleIsActive, "Sale must be active to adopt a Cheetah");
        }
        require(_count < maxCheetahPurchase, "Exceeds limit of 5");
        uint256 supply = totalSupply();
        require(
            supply + _count < MAX_CHEETAHS,
            "Max supply of Cheetahs reached"
        );
        require(
            msg.value == cheetahPrice.mul(_count),
            "Ether value sent is not correct"
        );

        for (uint256 i = 1; i <= _count; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        CHEETAH_PROVENANCE = provenanceHash;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setPrice(uint256 _price) public onlyOwner {
        cheetahPrice = _price;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdrawAll() public payable onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        uint256 seventyfive = address(this).balance.mul(75).div(100); //75%
        uint256 twenty = address(this).balance.mul(20).div(100); //10%
        uint256 five = address(this).balance.mul(5).div(100); //5%
        require(payable(a1).send(seventyfive));
        require(payable(a2).send(twenty));
        require(payable(a3).send(five));
    }
}