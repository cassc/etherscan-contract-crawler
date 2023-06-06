// SPDX-License-Identifier: MIT

/*
            .-========================================-.
           +********************************************=
          =**********************************************+
          +******+=-::::::::::::::::::::::::::::-=+*******
          +*****-:................................:-******         ::
          +****+:..................................:+*****       .++++-.
          *****=:....-===============-....:===-....:+*****        :+++++-
          *****=:....+***************+....-***+....:+*****          -+++++:
          *#***=:....+***************+....-***+....:+***#*           :+++++=
          *#***=:.....:::::::::::::::......:::.....:+***#*            .+++++=
          *####=:..................................:+####*           .:-------:.
          *####+:....=+++++++++++++++=....:+++=....:+####*      :=+**--::::::::-
          *####+:....+***************+....-***+....:+####*    :*##*=---::::::::-
          *####+:....=***************=....:+**=....:+####*   -##*:   --::::::::-
          *####+:..................................:+####*   *#*:    --::::::::-
          *####*-:................................:-*####*   *#*:    --::::::::-
          *#####*=-::::::::::::::::::::::::::::::-=######*   -##*:   --::::::::-
          +########*****************************#########*    :*##*=---::::::::-
          .*############################################*.      :=**#--::::::::-
            -+**####################################**+-             :---------:
                ####################################.                   +++++
                *###################################++++-.              +++++
                +##################################*++++++=.            +++++
                =##################################+:-++++++            +++++
                -##################################:   =++++:           +++++
                :##################################.   :++++-           +++++
                .##################################    -++++:           +++++
                 #################################*    +++++            +++++
                 *################################+   =++++-            +++++
                 +################################=  .+++++             +++++
                 =################################-  -++++=            .+++++
                 -################################:  =++++-            :+++++
                 :################################.  -+++++            +++++=
                 .################################    =+++++:        :++++++.
                  ################################     -+++++++====++++++++.
                  ###############################*      .-++++++++++++++=:
             .....*##############################+.....    .:-==+++==-:
          .+********************************************=
          +*############################################*=
          ------------------------------------------------
*/

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract FCKGAS is ERC721A, Ownable {
    using Strings for uint256;
    string public baseURI = "ipfs://QmWKAvvK1GEJQKwU49wU3yy6xrFfkWCMxdpqnbjhyc5AHn/";
    uint256 public price = 0.003 ether;
    uint256 public maxPerTx = 20;
    uint256 public maxFreePerWallet = 1;
    uint256 public totalFree = 4469;
    uint256 public maxSupply = 4469;
    bool public mintEnabled = false;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor(uint256 _preMint) ERC721A("FCKGAS", "FGAS") {
        _safeMint(msg.sender, _preMint);
    }

    function mint(uint256 count) external payable {
        uint256 cost = price;
        bool isFree = ((totalSupply() + count < totalFree + 1) &&
        (_mintedFreeAmount[msg.sender] + count <= maxFreePerWallet));

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Send the exact amount");
        require(totalSupply() + count < maxSupply + 1, "Not enough NFTs left to mint");
        require(mintEnabled, "Sales are off");
        require(count < maxPerTx + 1, "Max per TX reached");

        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}