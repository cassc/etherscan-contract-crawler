// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

/*
                                                                                           
     #@@@@@@@@@@@@                                                                         
   @@@@@@@@@@@@@@@@@                                                                       
   @@@@@@@@@@@@@@@@@                                                                       
     #@@@@@@@@@@@@  @@@@    @@@@*    @@@@@@@@    @@@@@@@@@@@  @@@@          @@@@@@@@%      
     #@@@@((  @@@@  @@@@    @@@@* [email protected]@@@((((((    @@@@((((((/  @@@@        @@@@(((((*,      
     #@@@@    @@@@  @@@@@@  @@@@* [email protected]@@@  @@@@@@  @@@@@@@@/    @@@@        @@@@@@@@,        
     #@@@@@@@@@@@@  @@@@@@@@@@@@* [email protected]@@@  @@@@@@  @@@@@@@@(    @@@@          @@@@@@@@@      
     #@@@@@@@@@@@@  @@@@  @@@@@@* [email protected]@@@    @@@@  @@@@         @@@@              @@@@@      
     #@@@@    @@@@  @@@@    @@@@* [email protected]@@@@@@@@@@@  @@@@@@@@@@@  @@@@@@@@@@  @@@@@@@@@@@      
     /####    ####  ####    ####,    #######(    ##########(  ##########  ########.        
                                                                                           
                                                     @@           @@      @@@@@@@@,        
                                                     @@@@(      @@@@    @@@@@@@@@@,        
                                                     @@@@(      @@@@    @@@@               
                                                     @@@@@@&  @@@@@@    //@@@@@@@&.        
                                                       @@@@@@@@@@@            @@@@,        
                                                         (@@@@@@        @@@@@@@@@@,        
                                                           ,@@          @@@@@@@@           
                                                                                           
     #%%%%%%%%      %%%%%%%%%%. /%#        %%    &&&&&&    .&&&&    &&&&    &&&&&%%%#      
     &@@@@@@@@@@    @@@@@@@@@@, #@@@@    @@@@  @@@@@@@@@@( ,@@@@    @@@@  @@@@@@@@@@&      
     &@@@@  @@@@@@  @@@@        #@@@@@@@@@@@@  @@@@  @@@@( ,@@@@    @@@@  @@@@             
     &@@@@    @@@@  @@@@@@@@    #@@@@@@@@@@@@  @@@@  @@@@( ,@@@@@@  @@@@  @@@@@@@@,        
     &@@@@    @@@@  @@@@@@@@    #@@@@@@@@@@@@  @@@@  @@@@/ ,@@@@@@@@@@@@    @@@@@@@@&      
     &@@@@@@@@@@**  @@@@@@@@@@. #@&  @@@@  @@  @@@@@@@@@@/ ,@@@@  **@@@@  @@@@@@@@@@&      
     &@@@@@@@@      @@@@@@@@@@, #@&  @@@@  @@    @@@@@@    ,@@@@    @@@@  @@@@@@@@@@&      
                                #@&  @@@@  @@                                              
                                     @@@@                                                  
                                     @@@@                                                  
                                                                                           
*/

library AmountMintedBitPacker {
    function getAmountMintedInFreeMints(
        uint64 packed
    ) internal pure returns (uint16) {
        return uint16(packed);
    }

    function getAmountMintedInOgMints(
        uint64 packed
    ) internal pure returns (uint16) {
        return uint16(packed >> 16);
    }

    function getAmountMintedInWhitelistMints(
        uint64 packed
    ) internal pure returns (uint16) {
        return uint16(packed >> 32);
    }

    function getAmountMintedInPublicMints(
        uint64 packed
    ) internal pure returns (uint16) {
        return uint16(packed >> 48);
    }

    function setAmountMintedInFreeMints(
        uint64 packed,
        uint16 newValue
    ) internal pure returns (uint64) {
        uint64 mask = 0xffffffffffff0000;
        uint64 shifted = uint64(newValue);

        return (packed & mask) | shifted;
    }

    function setAmountMintedInOgMints(
        uint64 packed,
        uint16 newValue
    ) internal pure returns (uint64) {
        uint64 mask = 0xffffffff0000ffff;
        uint64 shifted = uint64(newValue) << 16;

        return (packed & mask) | shifted;
    }

    function setAmountMintedInWhitelistMints(
        uint64 packed,
        uint16 newValue
    ) internal pure returns (uint64) {
        uint64 mask = 0xffff0000ffffffff;
        uint64 shifted = uint64(newValue) << 32;

        return (packed & mask) | shifted;
    }

    function setAmountMintedInPublicMints(
        uint64 packed,
        uint16 newValue
    ) internal pure returns (uint64) {
        uint64 mask = 0x0000ffffffffffff;
        uint64 shifted = uint64(newValue) << 48;

        return (packed & mask) | shifted;
    }
}

contract AngelsVsDemons is ERC721A, OperatorFilterer, Ownable, ERC2981 {
    error IncorrectAmountError();
    error IncorrectSaleStageError();
    error ExceedsMaxSupplyError();
    error ExceedsWalletSupplyError();
    error InvalidProofError();

    enum SaleStage {
        CLOSED,
        PRIVATE,
        PUBLIC
    }

    bytes32 public freeMintsMerkleRoot;
    bytes32 public ogMintsMerkleRoot;
    bytes32 public wlMintsMerkleRoot;

    string public baseURI;

    SaleStage public saleStage = SaleStage.CLOSED;

    bool public operatorFilteringEnabled;

    uint256 public constant MAX_SUPPLY = 6666;
    uint256 public constant MAX_MINTS_OG = 6;
    uint256 public constant MAX_MINTS_FREE = 9;
    uint256 public constant MAX_MINTS_WL = 6;
    uint256 public constant MAX_MINTS_PUBLIC = 9;
    uint256 public constant PRICE_OG = 0.01 ether;
    uint256 public constant PRICE_WL = 0.015 ether;
    uint256 public constant PRICE_PUBLIC = 0.02 ether;

    event SaleStateUpdated(SaleStage oldState, SaleStage newState);
    event BaseUriUpdated(string prevBaseUri, string newBaseUri);
    event FreeMintsMerkleRootUpdated(
        bytes32 prevMerkleRoot,
        bytes32 newMerkleRoot
    );
    event OgMintsMerkleRootUpdated(
        bytes32 prevMerkleRoot,
        bytes32 newMerkleRoot
    );
    event WlMintsMerkleRootUpdated(
        bytes32 prevMerkleRoot,
        bytes32 newMerkleRoot
    );

    constructor(
        string memory initBaseURI,
        bytes32 _freeMintsMerkleRoot,
        bytes32 _ogMintsMerkleRoot,
        bytes32 _wlMintsMerkleRoot
    ) ERC721A("Angels vs Demons NFTs", "AvD") {
        baseURI = initBaseURI;
        freeMintsMerkleRoot = _freeMintsMerkleRoot;
        ogMintsMerkleRoot = _ogMintsMerkleRoot;
        wlMintsMerkleRoot = _wlMintsMerkleRoot;

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        _setDefaultRoyalty(msg.sender, 900); // 9%

        _mint(msg.sender, 666);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                      Modifiers                                      #
    // #                                                                                     #
    // #######################################################################################

    modifier verifySaleStageIsNotClosed() {
        if (saleStage == SaleStage.CLOSED) {
            revert IncorrectSaleStageError();
        }
        _;
    }

    modifier verifyAvailableSupply(uint256 amount) {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert ExceedsMaxSupplyError();
        }
        _;
    }

    modifier verifyAmount(uint256 amount, uint256 price) {
        if (msg.value != amount * price) {
            revert IncorrectAmountError();
        }
        _;
    }

    modifier verifyProof(bytes32[] calldata proof, bytes32 root) {
        bytes32 leaf = keccak256(abi.encode(msg.sender));

        if (!MerkleProof.verifyCalldata(proof, root, leaf)) {
            revert InvalidProofError();
        }
        _;
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                      Accessors                                      #
    // #                                                                                     #
    // #######################################################################################

    function setSaleStage(SaleStage newSaleStage) external onlyOwner {
        emit SaleStateUpdated(saleStage, newSaleStage);

        saleStage = newSaleStage;
    }

    function setBaseUri(string memory newUri) external onlyOwner {
        emit BaseUriUpdated(baseURI, newUri);

        baseURI = newUri;
    }

    function setFreeMintsMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        emit FreeMintsMerkleRootUpdated(freeMintsMerkleRoot, newMerkleRoot);

        freeMintsMerkleRoot = newMerkleRoot;
    }

    function setOgMintsMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        emit OgMintsMerkleRootUpdated(ogMintsMerkleRoot, newMerkleRoot);

        ogMintsMerkleRoot = newMerkleRoot;
    }

    function setWlMintsMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        emit WlMintsMerkleRootUpdated(wlMintsMerkleRoot, newMerkleRoot);

        wlMintsMerkleRoot = newMerkleRoot;
    }

    function withdraw(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       Minting                                       #
    // #                                                                                     #
    // #######################################################################################

    function mintFree(
        bytes32[] calldata merkleProof,
        uint16 amount
    )
        external
        payable
        verifySaleStageIsNotClosed
        verifyProof(merkleProof, freeMintsMerkleRoot)
        verifyAvailableSupply(amount)
    {
        uint64 packedAmountsMinted = _getAux(msg.sender);

        uint16 amountMintedInFreeMints = AmountMintedBitPacker
            .getAmountMintedInFreeMints(packedAmountsMinted);

        if (amountMintedInFreeMints + amount > MAX_MINTS_FREE) {
            revert ExceedsWalletSupplyError();
        }

        _mint(msg.sender, amount);

        uint64 updatedPackedAmountsMinted = AmountMintedBitPacker
            .setAmountMintedInFreeMints(
                packedAmountsMinted,
                amountMintedInFreeMints + amount
            );

        _setAux(msg.sender, updatedPackedAmountsMinted);
    }

    function mintOG(
        bytes32[] calldata merkleProof,
        uint16 amount
    )
        external
        payable
        verifySaleStageIsNotClosed
        verifyProof(merkleProof, ogMintsMerkleRoot)
        verifyAmount(amount, PRICE_OG)
        verifyAvailableSupply(amount)
    {
        uint64 packedAmountsMinted = _getAux(msg.sender);

        uint16 amountMintedInOgMints = AmountMintedBitPacker
            .getAmountMintedInOgMints(packedAmountsMinted);

        if (amountMintedInOgMints + amount > MAX_MINTS_OG) {
            revert ExceedsWalletSupplyError();
        }

        _mint(msg.sender, amount);

        uint64 updatedPackedAmountsMinted = AmountMintedBitPacker
            .setAmountMintedInOgMints(
                packedAmountsMinted,
                amountMintedInOgMints + amount
            );

        _setAux(msg.sender, updatedPackedAmountsMinted);
    }

    function mintWhitelist(
        bytes32[] calldata merkleProof,
        uint16 amount
    )
        external
        payable
        verifySaleStageIsNotClosed
        verifyProof(merkleProof, wlMintsMerkleRoot)
        verifyAmount(amount, PRICE_WL)
        verifyAvailableSupply(amount)
    {
        uint64 packedAmountsMinted = _getAux(msg.sender);

        uint16 amountMintedInWhitelistMints = AmountMintedBitPacker
            .getAmountMintedInWhitelistMints(packedAmountsMinted);

        if (amountMintedInWhitelistMints + amount > MAX_MINTS_WL) {
            revert ExceedsWalletSupplyError();
        }

        _mint(msg.sender, amount);

        uint64 updatedPackedAmountsMinted = AmountMintedBitPacker
            .setAmountMintedInWhitelistMints(
                packedAmountsMinted,
                amountMintedInWhitelistMints + amount
            );

        _setAux(msg.sender, updatedPackedAmountsMinted);
    }

    function mintPublic(
        uint16 amount
    )
        external
        payable
        verifyAmount(amount, PRICE_PUBLIC)
        verifyAvailableSupply(amount)
    {
        if (saleStage != SaleStage.PUBLIC) {
            revert IncorrectSaleStageError();
        }

        uint64 packedAmountsMinted = _getAux(msg.sender);

        uint16 amountMintedInPublicMints = AmountMintedBitPacker
            .getAmountMintedInPublicMints(packedAmountsMinted);

        if (amountMintedInPublicMints + amount > MAX_MINTS_PUBLIC) {
            revert ExceedsWalletSupplyError();
        }

        _mint(msg.sender, amount);

        uint64 updatedPackedAmountsMinted = AmountMintedBitPacker
            .setAmountMintedInPublicMints(
                packedAmountsMinted,
                amountMintedInPublicMints + amount
            );

        _setAux(msg.sender, updatedPackedAmountsMinted);
    }

    function airDrop(
        address[] calldata addresses,
        uint16[] calldata amounts
    ) external onlyOwner {
        if (addresses.length != amounts.length) {
            revert IncorrectAmountError();
        }

        uint256 newSupply = totalSupply();

        for (uint256 i = 0; i < amounts.length; i++) {
            newSupply += amounts[i];
        }

        if (newSupply > MAX_SUPPLY) {
            revert ExceedsMaxSupplyError();
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], amounts[i]);
        }
    }

    function getMintedAmounts(
        address minter
    ) external view returns (uint16, uint16, uint16, uint16) {
        uint64 packedAmountsMinted = _getAux(minter);

        uint16 amountMintedInFreeMints = AmountMintedBitPacker
            .getAmountMintedInFreeMints(packedAmountsMinted);

        uint16 amountMintedInOgMints = AmountMintedBitPacker
            .getAmountMintedInOgMints(packedAmountsMinted);

        uint16 amountMintedInWhitelistMints = AmountMintedBitPacker
            .getAmountMintedInWhitelistMints(packedAmountsMinted);

        uint16 amountMintedInPublicMints = AmountMintedBitPacker
            .getAmountMintedInPublicMints(packedAmountsMinted);

        return (
            amountMintedInFreeMints,
            amountMintedInOgMints,
            amountMintedInWhitelistMints,
            amountMintedInPublicMints
        );
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC721A                                       #
    // #                                                                                     #
    // #######################################################################################

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json"));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC2981                                       #
    // #                                                                                     #
    // #######################################################################################

    function setDefaultRoyalty(
        address payable receiver,
        uint96 numerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC165                                        #
    // #                                                                                     #
    // #######################################################################################

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                  OperatorFilterer                                   #
    // #                                                                                     #
    // #######################################################################################

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71

        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}