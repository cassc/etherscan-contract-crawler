// SPDX-License-Identifier: MIT

// ██████╗░██╗░░░██╗███╗░░██╗██╗░░██╗░██████╗
// ██╔══██╗██║░░░██║████╗░██║██║░██╔╝██╔════╝
// ██████╔╝╚██╗░██╔╝██╔██╗██║█████═╝░╚█████╗░
// ██╔═══╝░░╚████╔╝░██║╚████║██╔═██╗░░╚═══██╗
// ██║░░░░░░░╚██╔╝░░██║░╚███║██║░╚██╗██████╔╝
// ╚═╝░░░░░░░░╚═╝░░░╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

pragma solidity 0.8.9;
pragma abicoder v2;

contract WeStandAgainstEvil is ERC1155, Ownable {

    uint256 public closingBlockNumber = 0;

    bool public saleIsActive = false;
    bool public singleUse = false;
    bool founderHasMinted = false;

    uint256 public thePrice = 2000000000000000; // 0.002 ETH - 5 dollar open edition

    string public _baseURI = "https://ipfs.io/ipfs/QmcRKjeCo5wN8quYvq6vwawYYePdhbtTnC3FuY2pLTvFA4/";

    // Withdraw address
    address t1 = 0x165CD37b4C644C2921454429E7F9358d18A45e14; // Ukraine
    // https://twitter.com/Ukraine/status/1497594592438497282?s=20&t=2Vom40nEaps_gw9dsLaYSQ

    constructor() ERC1155(_baseURI) { }
    
   function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

    function withdraw() public onlyOwner {
        uint256 _total = address(this).balance;
        require(payable(t1).send(_total)); // Ukraine
    }

    function setThePrice(uint256 newPrice) public onlyOwner {
        thePrice = newPrice;
    }

    function flipSaleState() public onlyOwner {
        require(!singleUse, "This function can only be performed once");
        saleIsActive = !saleIsActive;
        closingBlockNumber = block.number + 6500; // 1 day of eth blocks
        singleUse = !singleUse;
    }

    // Minting

    function publicMint(uint PVNKS) public payable {
        require(saleIsActive, "Public Sale is not active");
        require(block.number < closingBlockNumber); // https://etherscan.io/blocks 
        require(PVNKS > 0 && PVNKS <= 10, "Max 10 per transaction");
        require(msg.value >= thePrice * PVNKS, "Ether value sent is incorrect");

            _mint(msg.sender, 1, PVNKS, "0x0000");
    } 

    function founderMint() public onlyOwner {
        require(!founderHasMinted, "These tokens have already been minted");
            _mint(msg.sender, 1, 3, "0x0000");
            founderHasMinted = !founderHasMinted;
    } 

}