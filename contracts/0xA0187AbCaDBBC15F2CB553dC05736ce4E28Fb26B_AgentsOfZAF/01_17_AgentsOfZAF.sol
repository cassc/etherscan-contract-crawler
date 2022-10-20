//SPDX-License-Identifier: MIT

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/////////.//////////////////////////////////////////////////////////////////////
////////..//////////////////////////////////////////////////////////////////////
////////....////////////////////////////////////////////////////////////////////
////////.....//////////////////////////////////////////////////////////////.////
////////.......//////////////////////////////////////////////////////////...////
////////........../////////////////////////////////////////////////////..../////
/////////............////////////////////////////////////////////////....../////
//////////[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//.......//////
//////////[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&...........///////
///////////[email protected]@@@@@@@@@@@@@@@@(/&@@@@@@@@@@@@/..............////////
////////////(.........(@&/%@@@//@@@@@@@@///(@@@@@@@@@@@@//............//////////
////////////(@@@../@@@@%///////////////////////(#%%&@@@///..........////////////
////////////(@@@@@@@@@@///////////////////////////////////,.....,///////////////
////////////(@@@@@@@@@//#@@@@@@@@@@@%///////////////////////@@@@@///////////////
////////////(@@@@@@@@@/@/@#//////@@@#/////////////@@@@@@@@@/@@@@@///////////////
////////////(@@@@@@@@%///@@@////(@@//////////////////#@////(@@@@@///////////////
////////////(@@@@@@@@&/////@&@@@@&//////////////@@///#&////&@@@@@///////////////
////////////(@@@@@@@@@//////////////////////////@@@@@//////@@@@@@///////////////
////////////(@@@@@@@@@////////%&#///////////////&////@&////@@@@@@///////////////
////////////(@@@@@@@@@/////////////////////////////////////@@@@@@///////////////
////////////(@@@@@@@@@&///////////////////////////////////@@@@@@@///////////////
////////////(@@@@@@@@@@/////////////%%@@&///////////////&@@@@@@@@///////////////
////////////(@@@@@@&@@@&////////////[email protected]@@@@@@@////////@&/@@@@@@@@///////////////
////////////(@@@@@@/@@@@/@@////////.///////////////#@////@@@@@@@@///////////////
////////////(@@@@@@@/@@@@////&@&////////////////(&//////@@@@@@@@@///////////////
//////////////(@@@@@@///@@//////////%@(/////(@/////////@@@@@#///////////////////
//////////////////////////////////////////////////////@&////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// By @madebypanda_ at https://topdogstudios.io 🐶🧟‍♀️

pragma solidity ^0.8.17;

import "./ERC721APreapproved.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

error SaleStateClosed();
error InvalidSignature();
error SaleStateNotActive();
error SaleStateWalletLimitExceeded(uint256 limitLeft);
error SaleStateTotalLimitExceeded(uint256 limitLeft);
error MaxSupplyExceeded(uint256 supply);
error IncorrectFunds(uint256 fundsRequired);

contract AgentsOfZAF is ERC721APreapproved, EIP712, IERC2981, PaymentSplitter {
    enum SaleState {
        CLOSED,
        PREMINT,
        IMMUNITY_BOOST,
        PUBLIC_AWARENESS,
        LAST_MINUTE_SURVIVOR
    }

    struct SaleParams {
        uint256 PREMINT;
        uint256 IMMUNITY_BOOST;
        uint256 PUBLIC_AWARENESS;
        uint256 LAST_MINUTE_SURVIVOR;
    }

    struct SaleStatesWalletSupply {
        mapping(SaleState => uint256) saleStateWalletLimit;
    }

    struct SaleConfigs {
        mapping(SaleState => uint256) saleStateToSalePrice;
        mapping(SaleState => uint256) saleStateToWalletLimit;
        mapping(SaleState => uint256) saleStateTotalLimit;
    }

    struct MintKey {
        SaleState saleState;
        uint8 quantity;
        bool vip;
        address to;
    }

    struct Addresses {
        address signer;
        address treasury;
        address openSeaProxyRegistryAddress;
        address looksRareTransferManagerAddress;
    }

    bytes32 private constant MINTKEY_TYPE_HASH = keccak256("MintKey(uint8 saleState,uint8 quantity,bool vip,address to)");
    uint256 private constant MAX_SUPPLY = 4242;

    string private _baseTokenURI;
    uint256 private _royaltyBps;
    uint256 private _bonusMint;
    SaleState private _saleState;
    SaleConfigs private _saleConfig;
    Addresses private _addresses;

    mapping(address => SaleStatesWalletSupply) private _mintedPerSaleState;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 royaltyBps,
        address[] memory payees,
        uint256[] memory shares,
        SaleParams memory salePrices,
        SaleParams memory walletLimits,
        SaleParams memory salelimits,
        Addresses memory addresses
    )
        ERC721APreapproved(
            name,
            symbol,
            addresses.openSeaProxyRegistryAddress,
            addresses.looksRareTransferManagerAddress
        )
        EIP712(name, "1")
        PaymentSplitter(payees, shares)
    {
        _baseTokenURI = baseTokenURI;
        _royaltyBps = royaltyBps;
        _addresses.signer = addresses.signer;
        _addresses.treasury = addresses.treasury;

        _saleConfig.saleStateToSalePrice[SaleState.PREMINT] = salePrices.PREMINT;
        _saleConfig.saleStateToSalePrice[SaleState.IMMUNITY_BOOST] = salePrices.IMMUNITY_BOOST;
        _saleConfig.saleStateToSalePrice[SaleState.PUBLIC_AWARENESS] = salePrices.PUBLIC_AWARENESS;
        _saleConfig.saleStateToSalePrice[SaleState.LAST_MINUTE_SURVIVOR] = salePrices.LAST_MINUTE_SURVIVOR;

        _saleConfig.saleStateToWalletLimit[SaleState.PREMINT] = walletLimits.PREMINT;
        _saleConfig.saleStateToWalletLimit[SaleState.IMMUNITY_BOOST] = walletLimits.IMMUNITY_BOOST;
        _saleConfig.saleStateToWalletLimit[SaleState.PUBLIC_AWARENESS] = walletLimits.PUBLIC_AWARENESS;
        _saleConfig.saleStateToWalletLimit[SaleState.LAST_MINUTE_SURVIVOR] = walletLimits.LAST_MINUTE_SURVIVOR;

        _saleConfig.saleStateTotalLimit[SaleState.PREMINT] = salelimits.PREMINT;
        _saleConfig.saleStateTotalLimit[SaleState.IMMUNITY_BOOST] = salelimits.IMMUNITY_BOOST;
        _saleConfig.saleStateTotalLimit[SaleState.PUBLIC_AWARENESS] = salelimits.PUBLIC_AWARENESS;

    }

    modifier doesNotExceedMaxSupply(uint256 quantity) {
        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded(MAX_SUPPLY);
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getPrice(bool vip) public view returns (uint256) {
        SaleState saleState = getSaleState();
        if (saleState == SaleState.CLOSED) revert SaleStateClosed();
        uint256 price = _saleConfig.saleStateToSalePrice[saleState];
        if (vip && saleState == SaleState.IMMUNITY_BOOST) price = (price * 4) / 5;

        return price;
    }

    function getSaleState() public view returns (SaleState) {
        return _saleState;
    }

    function getWalletRemainingLimitBySale(address to) public view returns (uint256) {
        SaleState saleState = getSaleState();
        return _saleConfig.saleStateToWalletLimit[saleState] - _mintedPerSaleState[to].saleStateWalletLimit[saleState];
    }

    function getTotalRemainingLimitBySale() public view returns (uint256) {
        SaleState saleState = getSaleState();
        if (saleState == SaleState.LAST_MINUTE_SURVIVOR) return MAX_SUPPLY - totalSupply();
        return _saleConfig.saleStateTotalLimit[saleState] - totalSupply();
    }

    function setSalePrices(SaleParams memory salePrices) external onlyOwner {
        _saleConfig.saleStateToSalePrice[SaleState.PREMINT] = salePrices.PREMINT;
        _saleConfig.saleStateToSalePrice[SaleState.IMMUNITY_BOOST] = salePrices.IMMUNITY_BOOST;
        _saleConfig.saleStateToSalePrice[SaleState.PUBLIC_AWARENESS] = salePrices.PUBLIC_AWARENESS;
        _saleConfig.saleStateToSalePrice[SaleState.LAST_MINUTE_SURVIVOR] = salePrices.LAST_MINUTE_SURVIVOR;
    }

    function setSaleState(SaleState saleState) external onlyOwner {
        _saleState = saleState;
    }

    function reserveAgents(address to, uint256 quantity) external doesNotExceedMaxSupply(quantity) onlyOwner {
        _safeMint(to, quantity);
    }

    function mintAgents(bytes memory signature, MintKey calldata mintKey) external payable doesNotExceedMaxSupply(mintKey.quantity) {   
        SaleState saleState = getSaleState();
        uint256 quantity = mintKey.quantity;
        
        if (saleState != mintKey.saleState)
            revert SaleStateNotActive();

        if (!(getPrice(mintKey.vip) * quantity == msg.value)) 
            revert IncorrectFunds(getPrice(mintKey.vip) * quantity);

        if (quantity > getWalletRemainingLimitBySale(mintKey.to)) 
            revert SaleStateWalletLimitExceeded(getWalletRemainingLimitBySale(mintKey.to));

        if (quantity > getTotalRemainingLimitBySale()) 
            revert SaleStateTotalLimitExceeded(getTotalRemainingLimitBySale());


        if (saleState == SaleState.PREMINT || saleState == SaleState.IMMUNITY_BOOST) {
            if (!verify(signature, mintKey)) revert InvalidSignature();
        }

        if (saleState != SaleState.PREMINT && _bonusMint < 42 && quantity >= 4) {
            quantity += 1;
            _bonusMint ++;
        }
        
        _mintedPerSaleState[mintKey.to].saleStateWalletLimit[saleState] += quantity;
        
        _safeMint(mintKey.to, quantity);
    }

    function burnAgent(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert TransferCallerNotOwnerNorApproved();
        _burn(tokenId);
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    ) external view override returns (address, uint256) {
        return (_addresses.treasury, ((_salePrice * _royaltyBps) / 10000));
    }

    function setRoyaltyBps(uint256 royaltyBps) external onlyOwner {
        _royaltyBps = royaltyBps;
    }

    function setTreasury(address treasury) external onlyOwner {
        _addresses.treasury = treasury;
    }

    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A)
        returns (bool)
    {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    function verify(bytes memory signature, MintKey calldata mintKey)
        public
        view
        returns (bool)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MINTKEY_TYPE_HASH,
                    mintKey.saleState,
                    mintKey.quantity,
                    mintKey.vip,
                    mintKey.to
                )
            )
        );

        return ECDSA.recover(digest, signature) == _addresses.signer;
    }
}