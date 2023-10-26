// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFractonXFactory {

    struct ERC20Info {
        address erc721Addr;
        bool isOriginal;        // is Original ERC20
        uint256 swapRatio;      // 1 erc721 => 1 * swapRatio erc20
        uint256 balance;
    }

    struct ERC721Info {
        address erc20Addr;
        uint256[] tokenIds;
    }

    struct Pair {
        address erc20Addr;
        address erc721Addr;
    }

    event EventUpdateRelation(address erc721Addr, address erc20Addr, uint256 swapRatio, bool isOriginERC20);
    event EventSetFractonXVault(address transVault, address swapVault);
    event EventSetTransferFee(address erc20Addr, uint256 feeRate);
    event EventSetURI(address erc721Addr, string uri);
    event EventSwap(address erc721Addr, address erc20Addr, uint256 inTokenId, uint256 amountIn20,
        uint256 outTokenId, uint256 amountOut20);
    event EventSetSwapFeeRate(uint256);
    event EventSetCloseSwap721To20(uint256);

    function createERC20(address erc721Addr, uint256 swapRatio, string memory name, string memory symbol,
        uint256 erc20TransferFee) external returns(address erc20Addr);

    function createERC721(address erc20Addr, uint256 swapRatio, string memory name,
        string memory symbol, string memory tokenUri) external returns(address erc721Addr);

    function swapERC20ToERC721(address erc20Addr, address to) external;

    function swapERC721ToERC20(address erc721Addr, uint256 tokenId, address to) external;

    function emergencyUpdatePair(address erc721Addr, address erc20Addr, uint256 swapRatio,
        bool isOriginalERC20) external;

    function setSwapWhiteList(address user, address erc721Addr, bool isGrant) external;

    function setTransferFee(address erc20Addr, uint256 fee) external;

    function set721URI(address erc721Addr, string calldata uri) external;

    function setSwapFeeRate(uint256 swapFeeRate2) external;

    function setFractonXVault(address transVault, address swapVault) external;

    function setCloseSwap721To20(uint256 status) external;

    function numberOfNFT(address NFTContract) external view returns (uint256);

    function getERC20Info(address erc20Addr) external view returns(ERC20Info memory erc20Info);

    function getERC721Info(address erc721Addr) external view returns(ERC721Info memory erc721Info);

    function swapFeeRate() external view returns(uint256);

    function closeSwap721To20() external view returns(uint256);

    function fractionxSwapVault() external view returns(address);

    function fractionxTransVault() external view returns(address);

}