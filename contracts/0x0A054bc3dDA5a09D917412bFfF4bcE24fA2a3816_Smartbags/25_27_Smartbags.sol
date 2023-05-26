//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

import '@0xdievardump/niftyforge/contracts/Modules/NFBaseModuleSlim.sol';
import '@0xdievardump/niftyforge/contracts/Modules/INFModuleTokenURI.sol';
import '@0xdievardump/niftyforge/contracts/Modules/INFModuleWithRoyalties.sol';
import '@0xdievardump/niftyforge/contracts/INiftyForge721Slim.sol';

import '@0xsequence/sstore2/contracts/SSTORE2.sol';

import './utils/Base64.sol';
import './SmartbagsUtils.sol';

interface IRenderer {
    function render(
        address contractAddress,
        string memory tokenNumber,
        string memory name,
        SmartbagsUtils.Color memory color,
        bytes memory texture,
        bytes memory fonts
    ) external pure returns (string memory);
}

interface IBagOpener {
    function open(
        uint256 tokenId,
        address owner,
        address operator,
        address contractAddress
    ) external;

    function render(uint256 tokenId, address contractAddress)
        external
        view
        returns (string memory);
}

/// @title Smartbags
/// @author @dievardump
contract Smartbags is
    Ownable,
    NFBaseModuleSlim,
    INFModuleTokenURI,
    INFModuleWithRoyalties,
    ReentrancyGuard
{
    using Strings for uint256;
    using SafeERC20 for IERC20;

    event BagsOpened(address operator, uint256[] tokenIds);

    error ShopIsClosed();
    error NoCanDo();
    error AlreadyMinted();
    error OutOfJpegs();

    error TooEarly();
    error AlreadyOpened();

    error ContractLocked();
    error NotAuthorized();

    error NotMinted();
    error OnlyContracts();

    error OnlyAsh();

    error WrongValue(uint256 expected, uint256 received);

    struct Payment {
        address token;
        uint96 unitPrice;
    }

    /// @notice the contract to open the bags
    address public bagOpener;

    /// @notice if public can start  minting bags
    bool public collectActive;

    /// @notice contains pointers to where the files are saved
    /// 0 => first half of texture
    /// 1 => second half of texture
    /// 2 => fonts
    // Given my thoughts on saving files like this on-chain, you can consider this
    // as me officially selling my Soul to Nahiko.
    mapping(uint256 => address) public files;

    /// @notice if updates to this contract (renderer etc...) are locked or not.
    bool public locked;

    /// @notice contract on which nfts are created
    address public nftContract;

    /// @notice if the bag has been opened.
    mapping(uint256 => bool) public openedBags;

    /// @notice the payment token.
    Payment public payment;

    /// @notice allows to update the base renderer (just for the image)
    address public renderer;

    /// @notice token contract for each NFT
    mapping(uint256 => address) public tokenToContract;

    /// @notice token id for each contract minted
    mapping(address => uint256) public contractToToken;

    constructor(
        address renderer_,
        string memory moduleURI,
        Payment memory payment_,
        bool activateCollect,
        address owner_
    ) NFBaseModuleSlim(moduleURI) {
        renderer = renderer_;

        payment = payment_;

        collectActive = activateCollect;

        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
    }

    ////////////////////////////////////////////////////
    ///// Module                                      //
    ////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(INFModuleTokenURI).interfaceId ||
            interfaceId == type(INFModuleWithRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(address, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        address contractAddress = tokenToContract[tokenId];
        if (address(0) == contractAddress) revert NotMinted();

        // if bag is opened, rendering not managed here.
        return
            openedBags[tokenId]
                ? IBagOpener(bagOpener).render(tokenId, contractAddress)
                : _render(tokenId, contractAddress);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(address, uint256)
        public
        view
        override
        returns (address receiver, uint256 basisPoint)
    {
        return (owner(), 420);
    }

    ////////////////////////////////////////////////////
    ///// Getters / Views                             //
    ////////////////////////////////////////////////////

    /// @notice returns the json for the bag with some metadata
    /// @param contractAddress the contract address
    /// @param tokenNumber the token number (4 characters string)
    /// @return uri the data uri for the nft
    /// @return name the name of the contract
    /// @return color the color of the bag
    /// @return minted if the contract has already been minted or not
    function renderWithData(address contractAddress, string memory tokenNumber)
        public
        view
        returns (
            string memory uri,
            string memory name,
            SmartbagsUtils.Color memory color,
            bool minted
        )
    {
        // if the contract is minted
        minted = isMinted(contractAddress);

        // get color from contract address
        color = SmartbagsUtils.getColor(contractAddress);

        // get contract name
        name = SmartbagsUtils.getName(contractAddress);

        // and the json.
        uri = IRenderer(renderer).render(
            contractAddress,
            tokenNumber,
            name,
            color,
            abi.encodePacked(SSTORE2.read(files[0]), SSTORE2.read(files[1])),
            SSTORE2.read(files[2])
        );
    }

    /// @notice Helper to know if a contract has been minted
    /// @return if the contract has been minted
    function isMinted(address contractAddress) public view returns (bool) {
        // some contracts are sacred.
        if (
            contractAddress ==
            address(0x21BEf5412E69cDcDA1B258c0E7C0b9db589083C3)
        ) {
            return true;
        }

        // we are forced to use both values because we start tokenIds at 0
        // therefore contractToToken will always return 0 for unminted contracts
        // I really feel like I can't say no to Nahiko.
        uint256 tokenId = contractToToken[contractAddress];
        address tokenContract = tokenToContract[tokenId];

        return tokenContract == contractAddress;
    }

    ////////////////////////////////////////////////////
    ///// Collectors                                  //
    ////////////////////////////////////////////////////

    /// @notice allows to collect a smartbag
    /// @param contractAddress the smart contract address to bag
    function collect(address contractAddress) public nonReentrant {
        if (!collectActive) {
            revert ShopIsClosed();
        }

        _proceedPayment(1);
        _collect(contractAddress);
    }

    /// @notice allows to collect several smartbags
    /// @param contractAddresses the smart contract addresses to bag
    function collectBatch(address[] calldata contractAddresses)
        public
        nonReentrant
    {
        if (!collectActive) {
            revert ShopIsClosed();
        }

        uint256 length = contractAddresses.length;
        _proceedPayment(length);
        for (uint256 i; i < length; i++) {
            _collect(contractAddresses[i]);
        }
    }

    /// @notice Allows holders to open their bag(s)
    /// @param tokenIds the list of token ids to open
    function openBags(uint256[] calldata tokenIds) external {
        address bagOpener_ = bagOpener;

        if (address(0) == bagOpener_) {
            revert TooEarly();
        }

        uint256 tokenId;
        address ownerOf;
        uint256 length = tokenIds.length;
        address nftContract_ = nftContract;
        for (uint256 i; i < length; i++) {
            tokenId = tokenIds[i];

            if (openedBags[tokenId]) {
                revert AlreadyOpened();
            }

            // owner or approvedForAll only
            ownerOf = IERC721(nftContract_).ownerOf(tokenId);
            if (
                msg.sender != ownerOf &&
                !IERC721(nftContract_).isApprovedForAll(ownerOf, msg.sender)
            ) {
                revert NotAuthorized();
            }

            openedBags[tokenId] = true;

            IBagOpener(bagOpener_).open(
                tokenId,
                ownerOf,
                msg.sender,
                tokenToContract[tokenId]
            );
        }

        emit BagsOpened(msg.sender, tokenIds);
    }

    ////////////////////////////////////////////////////
    ///// Contract Owner                              //
    ////////////////////////////////////////////////////

    /// @notice withdraws "token", just in case.
    function withdraw(address token) external onlyOwner {
        IERC20(token).safeTransfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    /// @notice locks changes in contract uri, renderer etc...
    function lock() external onlyOwner {
        locked = true;
    }

    /// @notice sets contract uri
    /// @param newURI the new uri
    function setContractURI(string memory newURI) external onlyOwner {
        if (locked) revert ContractLocked();
        _setContractURI(newURI);
    }

    /// @notice Allows owner to change the renderer (in case there is some error in the current)
    ///         only works if the contract hasn't been locked for changes
    /// @param newRenderer the new renderer address
    function setRenderer(address newRenderer) external onlyOwner {
        if (locked) revert ContractLocked();
        renderer = newRenderer;
    }

    /// @notice Allows owner to set the nftContract
    /// @param newNFTContract the new renderer address
    function setNFTContract(address newNFTContract) external onlyOwner {
        if (locked) revert ContractLocked();
        nftContract = newNFTContract;
    }

    /// @notice Allows owner to set the payment method
    /// @param newPayment the new payment method
    function setPayment(Payment calldata newPayment) external onlyOwner {
        if (locked) revert ContractLocked();
        payment = newPayment;
    }

    /// @notice Allows owner to set the payment method
    /// @param bagOpener_ the bag opener contract
    function allowOpening(address bagOpener_) external onlyOwner {
        if (locked) revert ContractLocked();
        bagOpener = bagOpener_;
    }

    /// @notice Allows owner to open / close minting
    /// @param activateCollect the new state
    function setCollectActive(bool activateCollect) external onlyOwner {
        collectActive = activateCollect;
    }

    /// @notice saves a file
    function saveFile(uint256 index, string calldata fileContent)
        external
        onlyOwner
    {
        files[index] = SSTORE2.write(bytes(fileContent));
    }

    ////////////////////////////////////////////////////
    ///// Internal                                    //
    ////////////////////////////////////////////////////

    /// @dev returns the json for the bag
    /// @param tokenId the token id for this bag
    /// @param contractAddress the contract address
    /// @return uri the data uri for the nft
    function _render(uint256 tokenId, address contractAddress)
        internal
        view
        returns (string memory uri)
    {
        (uri, , , ) = renderWithData(
            contractAddress,
            SmartbagsUtils.tokenNumber(tokenId)
        );
    }

    /// @dev proceeds the payment for `pieces` items
    function _proceedPayment(uint256 pieces) internal {
        Payment memory _payment = payment;
        if (address(0) == _payment.token) {
            if (msg.value != uint256(_payment.unitPrice) * pieces) {
                revert WrongValue({
                    expected: _payment.unitPrice,
                    received: msg.value
                });
            }
        } else {
            if (msg.value != 0) revert OnlyAsh();
            IERC20(_payment.token).safeTransferFrom(
                msg.sender,
                owner(),
                uint256(_payment.unitPrice) * pieces
            );
        }
    }

    function _collect(address contractAddress) internal {
        if (
            contractAddress ==
            address(0x21BEf5412E69cDcDA1B258c0E7C0b9db589083C3)
        ) {
            revert NoCanDo();
        }
        if (!Address.isContract(contractAddress)) revert OnlyContracts();
        if (isMinted(contractAddress)) revert AlreadyMinted();

        _mint(contractAddress);
    }

    function _mint(address contractAddress) internal {
        uint256 tokenId = INiftyForge721Slim(nftContract).mint(msg.sender);
        tokenToContract[tokenId] = contractAddress;
        contractToToken[contractAddress] = tokenId;
    }
}