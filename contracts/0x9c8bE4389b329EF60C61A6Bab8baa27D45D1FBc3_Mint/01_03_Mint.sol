// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IMint {
    event Minted(address targetAddress, uint tokenId);
    event AdminChanged(address oldAdmin, address newAdmin);
    event DevWalletChanged(address oldDevWallet, address newDevWallet);
    event WithdrawedBalance(address devWallet, uint amount);
    event Withdrawed(address devWallet, uint tokenId);
    event SalePriceChanged(uint oldPrice, uint newPrice);
}

contract Mint is IMint, Ownable {
    address payable public admin;
    address payable public devWallet =
        payable(0x3b3B9e2f88Fa57B41f0026F4E95E1cbd12C05ad9);
    IERC721 public crr = IERC721(0x9c6b5033Ee140082E55B4d8CA32EA72F8bbFB4A5);
    uint256 public salePrice = 0.2 ether;
    mapping(uint256 => uint256) public NFTs;
    uint256 public mintableAmount;

    constructor() {
        admin = payable(msg.sender);
    }

    function mint(address account, uint256[] memory tokenIds) public payable {
        uint mintAmount = tokenIds.length;
        require(
            crr.balanceOf(account) + mintAmount < 4,
            "One user can own only 3 NFTs"
        );
        for (uint i = 0; i < mintAmount; i++) {
            require(
                crr.ownerOf(tokenIds[i]) == address(this),
                "Contract does not have this NFT."
            );
        }
        require(
            msg.value >= salePrice * mintAmount,
            "Price is less than salePrice."
        );
        _checkMintables();
        for (uint i = 0; i < mintAmount; i++) {
            crr.approve(account, tokenIds[i]);
            crr.safeTransferFrom(address(this), account, tokenIds[i]);
            NFTs[tokenIds[i]] = 0;
            mintableAmount--;
            emit Minted(account, tokenIds[i]);
        }

        devWallet.transfer(msg.value);
    }

    function checkMintables() external {
        _checkMintables();
    }

    function _checkMintables() internal {
        mintableAmount = 0;
        for (uint i = 0; i < 111; i++) {
            if (crr.ownerOf(i) == address(this)) {
                NFTs[i] = i + 1;
                mintableAmount++;
            } else {
                NFTs[i] = 0;
            }
        }
    }

    function setAdmin(address payable _admin) public onlyOwner {
        require(_admin != address(0), "Ownable: new owner is the zero address");
        if (admin != _admin) {
            _transferOwnership(_admin);
            admin = _admin;
            emit AdminChanged(admin, _admin);
        }
    }

    function setDevWallet(address payable _devWallet) public onlyOwner {
        require(
            _devWallet != address(0),
            "Ownable: new owner is the zero address"
        );
        if (devWallet != _devWallet) {
            devWallet = _devWallet;
            emit DevWalletChanged(devWallet, _devWallet);
        }
    }

    function setSalePrce(uint _salePrice) public onlyOwner {
        if (salePrice != _salePrice) {
            salePrice = _salePrice;
            emit SalePriceChanged(salePrice, _salePrice);
        }
    }

    function withdrawETH() public onlyOwner {
        uint _balance = address(this).balance;
        admin.transfer(_balance);
        emit WithdrawedBalance(admin, _balance);
    }

    function withdrawNFTs() public onlyOwner {
        uint amount;
        for (uint i = 0; i < 111; i++) {
            if (crr.ownerOf(i) == address(this)) {
                crr.approve(devWallet, i);
                crr.transferFrom(address(this), devWallet, i);
                amount++;
            }
        }
        emit Withdrawed(devWallet, amount);
    }

    function getMintableNFTs() public view returns (uint256[] memory) {
        uint256[] memory _mintableNFTs = new uint256[](mintableAmount);
        uint j = 0;
        for (uint i = 0; i < 111; i++) {
            if (NFTs[i] != 0) {
                _mintableNFTs[j] = NFTs[i];
                j++;
            }
        }
        return _mintableNFTs;
    }

    function setToken(address _tokenAddress) public onlyOwner {
        crr = IERC721(_tokenAddress);
    }

    receive() external payable {}
}