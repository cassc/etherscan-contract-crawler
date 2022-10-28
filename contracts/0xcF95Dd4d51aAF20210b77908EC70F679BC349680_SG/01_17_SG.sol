// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Reclaimable.sol";

contract SG is ERC1155, Ownable, Reclaimable, ReentrancyGuard, IERC2981 {
    using Strings for uint256;

    string private _baseTokenURI = "https://sg-metadata.s3.us-east-2.amazonaws.com/metadata/";
    string private _contractURI = "https://sg-metadata.s3.us-east-2.amazonaws.com/collection/collection.json";

    IERC1155 public catsAddress;
    IERC1155 public ratsAddress;
    IERC1155 public crocsAddress;

    IERC721[] public eligible721; 

    address public forgeContract;

    uint256 public startTime;
    uint256 public endTime;

    uint256 private royaltyBps = 500;
    address private royaltyReceiver = 0x5748bf284B8e001bd535C5dE6e9C52EC64501FdC;

    mapping(uint256 => uint256) public idToPrice; 

    mapping(uint256 => uint256) public totalMinted;
    mapping(uint256 => uint256) public totalBurned;

    constructor() ERC1155(_baseTokenURI) {}

    function isHolder(address holder, uint256 erc1155Id) public view returns (bool) {
        if (catsAddress.balanceOf(holder, erc1155Id) > 0) return true;
        if (ratsAddress.balanceOf(holder, erc1155Id) > 0) return true;
        if (crocsAddress.balanceOf(holder, erc1155Id) > 0) return true;

        for (uint256 i = 0; i < eligible721.length; i++) {
            if (eligible721[i].balanceOf(holder) > 0) return true;
        }

        return false;
    }

    function isEligibleToMint(
        address holder,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        uint256 erc1155Id
    ) external view returns (string memory) {
        if (block.timestamp < startTime || block.timestamp > endTime) return "Mint is paused";
        if (ids.length != amounts.length) return "Invalid params";

        bool isUserHolder = isHolder(holder, erc1155Id);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 current = ids[i];
            if (idToPrice[current] == 0) return "Unknown id";
            if (amounts[i] > 50) return "Max per transaction exceeded";
            if (current >= 6 && current <= 10 && !isUserHolder) return "Can't mint holder bundle";
        }
        return "";
    }

    // minting functions
    function adminMint(address to, uint256 id, uint256 amount) external onlyOwner {
        _mint(to, id, amount, "");
    }

    function mint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        uint256 erc1155Id
    ) external payable nonReentrant {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Out of timeframe");
        require(ids.length == amounts.length, "Invalid length");
        uint256 priceToPay = 0;

        bool isUserHolder = isHolder(to, erc1155Id);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 current = ids[i];
            require (idToPrice[current] > 0, "Unknown id");
            require (amounts[i] <= 50, "Max per transaction exceeded");
            if (current >= 6 && current <= 10) require(isUserHolder, "Can't mint holder bundle");
            priceToPay += idToPrice[current] * amounts[i];
        }

        require(msg.value == priceToPay, "Invalid price");

        _mintBatch(to, ids, amounts, "");
    }

    // setup functions
    function setForgeContract(address _forgeContract) external onlyOwner {
        forgeContract = _forgeContract;
    }

    function setTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
    }

    function setCollections(
        address cats,
        address rats,
        address crocs,
        address[] calldata erc721s
    ) external onlyOwner {
        catsAddress = IERC1155(cats);
        ratsAddress = IERC1155(rats);
        crocsAddress = IERC1155(crocs);

        if (eligible721.length != 0) delete eligible721;
        for (uint256 i = 0; i < erc721s.length; i++) {
            eligible721.push(IERC721(erc721s[i]));
        }
    }

    function setPrices(uint256[] calldata ids, uint256[] calldata prices) external onlyOwner {
        for(uint256 i = 0; i < ids.length; i++) {
            idToPrice[ids[i]] = prices[i];
        }
    }

    // metadata-related functions
    function contractURI() public view returns(string memory) {
		return _contractURI;
	}

	function uri(uint _tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
	}

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function setContractURI(string calldata _newContractURI) external onlyOwner {
        _contractURI = _newContractURI;
    }

    // royalty
    function setRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
    }

    function setRoyaltyBps(uint256 _royaltyBps) external onlyOwner {
        royaltyBps = _royaltyBps;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
        royaltyAmount = (_salePrice / 10000) * royaltyBps;
        return (royaltyReceiver, royaltyAmount);
    }

    // forging
    function forge(address from, uint256 id, uint256 amount) external {
        require (msg.sender == forgeContract, "Can't forge");
        _burn(from, id, amount);
    }

    // total counters
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalMinted[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalBurned[ids[i]] += amounts[i];
            }
        }
    }


}