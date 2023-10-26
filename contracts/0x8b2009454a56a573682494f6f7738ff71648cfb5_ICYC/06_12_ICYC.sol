// SPDX-License-Identifier: MIT

/***************************************************************************
          ___        __         _     __           __   __ ___
        / __ \      / /_  _____(_)___/ /____       \ \ / /  _ \
       / / / /_  __/ __/ / ___/ / __  / __  )       \ / /| |
      / /_/ / /_/ / /_  (__  ) / /_/ / ____/         | | | |_
      \____/\____/\__/ /____/_/\__,_/\____/          |_|  \___/
                                       
****************************************************************************/

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";

interface IOSYCKey {
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function burn(address from, uint256 id, uint256 amount) external;

    function mintKey(address account, uint8 keyId, uint8 amount) external;
}

contract ICYC is ERC721Burnable {
    uint16 public MAX_SUPPLY;
    uint16 private mintedCount;

    uint256 public mintPrice;

    address private keyAddress = 0x875427563Cc7e083e55F0aBeE7Edc10f649e8E5B;

    constructor() ERC721("Individually Customized Yacht Club", "ICYC") {
        MAX_SUPPLY = 111;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setConfig(uint16 _MAX_SUPPLY) external onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function totalSupply() public view virtual returns (uint16) {
        return mintedCount;
    }

    function getTokensOfOwner(
        address owner
    ) public view returns (uint16[] memory) {
        uint16 tokenCount = uint16(balanceOf(owner));

        if (tokenCount == 0) {
            return new uint16[](0);
        } else {
            uint16[] memory result = new uint16[](tokenCount);
            uint16 resultIndex = 0;
            uint16 tokenId;

            for (tokenId = 0; tokenId < totalSupply(); tokenId++) {
                if (_owners[tokenId] == owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                    if (resultIndex >= tokenCount) {
                        break;
                    }
                }
            }
            return result;
        }
    }

    function mintFromKey(address _account, uint8 _amount) external payable {
        require(tx.origin == msg.sender, "Only EOA");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max Limit To Presale");
        require(IOSYCKey(keyAddress).balanceOf(msg.sender, 3) >= _amount,
            "Not enough WL"
        );
        IOSYCKey(keyAddress).burn(msg.sender, 3, _amount);
        for (uint8 i = 0; i < _amount; i += 1) {
            uint16 tokenId = totalSupply() + i;
            _safeMint(_account, tokenId);
        }
        mintedCount = mintedCount + _amount;
    }

    function mintFromETH(address _account, uint8 _amount) external payable {
        require(tx.origin == msg.sender, "Only EOA");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max Limit To Presale");
        require(mintPrice != 0, "Not enabled");
        require(mintPrice * _amount <= msg.value, "Insufficient value");

        for (uint8 i = 0; i < _amount; i += 1) {
            uint16 tokenId = totalSupply() + i;
            _safeMint(_account, tokenId);
        }
        mintedCount = mintedCount + _amount;
    }

    function reserveNft(address account, uint8 _amount) external onlyOwner {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max Limit To Presale");

        for (uint8 i = 0; i < _amount; i += 1) {
            uint16 tokenId = totalSupply() + i;
            _safeMint(account, tokenId);
        }
        mintedCount = mintedCount + _amount;
    }

    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        payable(msg.sender).transfer(totalBalance);
    }
}
