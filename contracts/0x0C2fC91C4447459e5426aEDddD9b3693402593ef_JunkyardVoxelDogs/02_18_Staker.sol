// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./JunkyardK9000.sol";

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract Staker is Ownable {
    struct Asset {
        address contractAddress;
        uint256 tokenId;
        string metadata;
    }
    //      asset =>           owner =>           tokenId => timestamp
    mapping(address => mapping(address => mapping(uint256 => uint256))) public stakings;
    IFxStateSender public fxRoot;
    address public fxChildTunnel;
    JunkyardK9000 k9000 = JunkyardK9000(0xa5849F0105B9a0e1811786d655dC7334B295FF18);

    constructor(address _fxRoot, address polyChild) {
        fxRoot = IFxStateSender(_fxRoot);
        fxChildTunnel = polyChild;
    }

    function setFxChildTunnel(address _fxChildTunnel) public onlyOwner {
        fxChildTunnel = _fxChildTunnel;
    }

    function getK9000(address account, uint256 lastTokenId) public view returns (uint256) {
        bool flag = false;
        uint256 totalSupply = k9000.totalSupply();
        for (uint256 i = 0; i < totalSupply; i++) {
            uint256 tokenId = k9000.builtK9000(i);
            if (tokenId == lastTokenId) {
                flag = true;
                continue;
            }
            if (flag && account == k9000.ownerOf(tokenId)) {
                return tokenId;
            }
        }
        return 0;
    }

    function getAssetNotEnnumerable(address account, address asset, uint256 lastTokenId) public view returns (uint256) {
        if (asset == address(k9000)) {
            return getK9000(account, lastTokenId);
        }
        ERC721Enumerable c = ERC721Enumerable(asset);
        uint256 supply = c.totalSupply();
        for (uint256 i = lastTokenId + 1; i <= supply; i++) {
            if (c.ownerOf(i) == account) {
                return i;
            }
        }
        return 0;
    }

    function unstakedAssets(address account, address[] calldata assets) public view returns (Asset[] memory) {
        uint256[] memory balances = new uint256[](assets.length);
        uint256 totalBalance = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            ERC721Enumerable c = ERC721Enumerable(assets[i]);
            balances[i] = c.balanceOf(account);
            totalBalance += balances[i];
        }
        Asset[] memory list = new Asset[](totalBalance);
        uint256 outerIndex = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 balance = balances[i];
            if (balance == 0) {
                continue;
            }
            ERC721Enumerable c = ERC721Enumerable(assets[i]);
            bool isEnnumerable = c.supportsInterface(type(IERC721Enumerable).interfaceId);
            for (uint256 j = 0; j < balance; j++) {
                uint256 tokenId = isEnnumerable ? c.tokenOfOwnerByIndex(account, j) : getAssetNotEnnumerable(account, assets[i], j == 0 ? 0 : list[outerIndex - 1].tokenId);
                string memory metadata = c.tokenURI(tokenId);
                list[outerIndex++] = Asset(assets[i], tokenId, metadata);
            }
        }
        return list;
    }

    function getAssetMetadata(address[] calldata addresses, uint256[] calldata tokenIds) public view returns (Asset[] memory) {
        require(addresses.length == tokenIds.length, "Both list must have the same amount of items");
        Asset[] memory list = new Asset[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            string memory metadata = ERC721(addresses[i]).tokenURI(tokenIds[i]);
            list[i] = Asset(addresses[i], tokenIds[i], metadata);
        }
        return list;
    }

    function stake(address[] calldata asset, uint256[] calldata tokenIds) public {
        require(asset.length == tokenIds.length, "The list of assets and tokenIds must have the same length");
        for (uint256 i = 0; i < asset.length; i++) {
            ERC721(asset[i]).transferFrom(msg.sender, address(this), tokenIds[i]);
            stakings[asset[i]][msg.sender][tokenIds[i]] = block.timestamp;
            sendMessageToChild(abi.encode(asset[i], msg.sender, tokenIds[i], true)); 
        }
    }

    function unstake(address[] calldata asset, uint256[] calldata tokenIds) public {
        require(asset.length == tokenIds.length, "The list of assets and tokenIds must have the same length");
        for (uint256 i = 0; i < asset.length; i++) {            
            ERC721(asset[i]).transferFrom(address(this), msg.sender, tokenIds[i]);
            delete stakings[asset[i]][msg.sender][tokenIds[i]];
            sendMessageToChild(abi.encode(asset[i], msg.sender, tokenIds[i], false));
        }
    }

    function sendMessageToChild(bytes memory message) public {
        fxRoot.sendMessageToChild(fxChildTunnel, message);
    }
}