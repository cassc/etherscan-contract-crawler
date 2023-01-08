// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface INFT {
    function mint(address, uint256, uint256, bytes memory) external;

    function addNFT(uint256, uint256, bool) external;

    function totalSupply(uint256) external returns (uint256);

    function supplyLeft(uint256) external returns (uint256);
}

interface myIERC20 is IERC20 {
    function decimals() external view returns (uint8);
}

contract T2SNFTSHOPV2 is Pausable, AccessControl {
    using SafeERC20 for myIERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    INFT public nft;
    // address public fundsRecipient;
    mapping(uint256 => uint256) public USDPrice;
    mapping(myIERC20 => bool) public allowedStable;
    mapping(uint256 => bool) public isSellAllowed;
    mapping(uint256 => address) public fundsRecipient;

    event NFTAdded(
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _supply,
        uint256 _number
    );

    constructor(INFT _nftAddress, myIERC20[] memory _stablecoinsAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        nft = _nftAddress;
        for (uint256 i; i < _stablecoinsAddress.length; i++) {
            allowedStable[_stablecoinsAddress[i]] = true;
        }
        // fundsRecipient = _fundsRecipient;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function addStable(myIERC20 _address) public onlyRole(ADMIN_ROLE) {
        require(!allowedStable[_address], "already allowed");
        allowedStable[_address] = true;
    }

    function removeStable(myIERC20 _address) public onlyRole(ADMIN_ROLE) {
        require(allowedStable[_address], "already removed");
        allowedStable[_address] = false;
    }

    /**
     * @dev Buy NFT with the specified token.
     * will revert if allowance is not set.
     * Please check for token alowance before calling this function.
     * You may need to call the "approve" function before.
     * @param _tokenId Id of the token to be minted
     */
    function buyInUSD(
        uint256 _tokenId,
        address _to,
        uint256 _amount,
        myIERC20 _stableAddress
    ) external whenNotPaused {
        require(
            fundsRecipient[_tokenId] != address(0),
            "Shop: recipient is address 0"
        );
        require(allowedStable[_stableAddress], "Shop: token not allowed");
        require(isSellAllowed[_tokenId], "Shop: sell not allowed");
        _stableAddress.safeTransferFrom(
            msg.sender,
            fundsRecipient[_tokenId],
            _amount * USDPrice[_tokenId] * 10 ** _stableAddress.decimals()
        );
        _mint(_to, _tokenId, _amount, "");
    }

    /**
     * @dev Set the price in USD (no decimals) of a given token
     * @param _tokenId Id of the token to change the price of
     * @param _price New price in USD (no decimals) for the token
     */
    function setPrice(
        uint256 _tokenId,
        uint256 _price,
        bool _allowSell
    ) public onlyRole(ADMIN_ROLE) {
        USDPrice[_tokenId] = _price;
        isSellAllowed[_tokenId] = _allowSell;
    }

    function addNFT(
        uint256 _price,
        uint256 _supply,
        uint256 _number,
        uint256 _tokenId,
        address _fundsRecipient,
        bool _activate
    ) external onlyRole(ADMIN_ROLE) {
        nft.addNFT(_supply, _number, _activate);
        require(
            nft.supplyLeft(_tokenId) == _supply &&
                nft.totalSupply(_tokenId) == 0,
            "NFTSHOP: bad nft supply"
        );
        fundsRecipient[_tokenId] = _fundsRecipient;
        setPrice(_tokenId, _price, _activate);
        emit NFTAdded(_tokenId, _price, _supply, _number);
    }

    /**
     * @dev Mint a specific amount of a given token
     * @param _to Address that will receive the token
     * @param _tokenId Id of the token to mint
     * @param _amount Amount to mint
     */
    function _mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) internal {
        nft.mint(_to, _tokenId, _amount, _data);
    }

    function changeFundRecipient(
        uint256 _tokenId,
        address _fundsRecipient
    ) external onlyRole(ADMIN_ROLE) {
        require(
            fundsRecipient[_tokenId] != _fundsRecipient,
            "Shop: same fundRedcipient"
        );
        fundsRecipient[_tokenId] = _fundsRecipient;
    }
}