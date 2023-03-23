// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/*
..........,+??%SSSS?;......;%SSSSSSSS%*,..........
........,+?%%%SSS%;,.....;?SSSSSSSSSSSSS*,........
......,+?%%%%SS?;,.....;?SSSSSSS*+%SS%SSS%+,......
....,+?%%%%%%?;,.....;?SSSSSSS*:..,;%SSSSSS%+,....
..,+?%%%%%%?;,.....;?##S%%SSSS;.....,;?SSSS%S%+,..
,+?%%%%%%?;,.....;%####%%%SSS##%;.....,;%SSSSSS%+,
%%%%%%S?;,.....:?S######?*SSS####?;.....,+%SS%%%%%
%%SSS?;,.....:?SSSSS##?:..:*S###SSS?;.....,;%SS%SS
%SS?;,.....:*%%%%%SS*:......:?S#SSSSS?:.....,;?S#S
S%;,.....:*%%%%%S%*:..........:*SSSS%%S?;.....,+S#
;,.....:?%%%%?%%%?..............%SSSSSSSS?;.....,;
.....:?SSS%%%%??%?;;;;;;;;;;;;;;%SSSSS%SS%S?;.....
...:?SSSSSS%%%%%%%SSS#S#####SSS#SSSSSSSS%%%SS?;...
.:*%S%SSS%**SSSS%SSS#S######SS##SSSSS%+*%SSSSSS?;.
?%%%%SSS*:.+SSSSS%???????%%%????SS%SS%;.:*%SSS%S#%
SSSSSS?:...+SSSSS?.............,%###S#;...:*SSS###
%SSSSS:....+SSSSS?..............S#####;....:#####S
SSSSSS:....+SSSSS%++++++++******S#####+....;#####S
SSSSSS:....+SSSSSSSSSSSSSSSS##########+....;#####S
SSSSSS:....+SSSSSSSSSSSSSSSSS#########+....;#####S
SSSSSS:....+SSSSS%**************S#####+....;#####S
SSSSSS:....+SSSSS?..............S####@+....;##@##S
SSSSSS:....+###SS?.............,S##@@@+....;#####S
S#####:....+#####%.............,[email protected]###@+....;@####S
*/
contract Amolution is ERC721A, ERC2981, Ownable {
    using SafeMath for uint256;

    bytes32 public merkleRoot;
    string public baseURI = "https://amolution.nyc3.digitaloceanspaces.com/reveal/json/";
    uint256 public startTime = 1679601600; //Mar 23 2023 20:00 UTC
    uint256 public price = 0.0085 ether;
    uint256 public whitelistStartTime = 1679601600; //Mar 23 2023 20:00 UTC
    uint256 public whitelistPrice = 0.0065 ether;
    uint256 public maxSupply = 1111;
    uint256 public maxPerWallet = 3;

    constructor() ERC721A("Amolution", "AMO") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(block.timestamp >= startTime, "Mint isn't started yet.");
        require(totalSupply().add(quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        require(_numberMinted(msg.sender).add(quantity) <= maxPerWallet, "The requested mint quantity exceeds the max per wallet limit.");
        require(price.mul(quantity) <= msg.value, "Not enough ETH for mint transaction.");

        _mint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) external payable {
        require(block.timestamp >= whitelistStartTime, "Mint isn't started yet.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof.");
        require(totalSupply().add(quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        require(_numberMinted(msg.sender).add(quantity) <= maxPerWallet, "The requested mint quantity exceeds the mint limit.");
        require(whitelistPrice.mul(quantity) <= msg.value, "Not enough ETH for mint transaction.");

        _mint(msg.sender, quantity);
    }

    function mintTo(uint256 _quantity, address _receiver) external onlyOwner {
        require(totalSupply().add(_quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        _mint(_receiver, _quantity);
    }

    function airdrop(address[] memory _addresses) external onlyOwner {
        require(totalSupply().add(_addresses.length) <= maxSupply, "The requested mint quantity exceeds the supply.");

        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1);
        }
    }

    function fundsWithdraw() external onlyOwner {
        uint256 funds = address(this).balance;
        require(funds > 0, "Insufficient balance.");

        (bool status,) = payable(msg.sender).call{value : funds}("");
        require(status, "Transfer failed.");
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(_interfaceId) || ERC2981.supportsInterface(_interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setWhitelistStartTime(uint256 _whitelistStartTime) external onlyOwner {
        whitelistStartTime = _whitelistStartTime;
    }

    function setWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }
}