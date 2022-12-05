// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./IERC4906A.sol";
import "./ArtGenerator.sol";
import "./BitSequence.sol";
import "./ERC721ASnapshotable.sol";

/* 
 * ,--.         ,---.,--.        ,--.  ,--.
 * `--',--,--, /  .-'`--',--,--, `--',-'  '-. ,---.
 * ,--.|      \|  `-,,--.|      \,--.'-.  .-'| .-. :
 * |  ||  ||  ||  .-'|  ||  ||  ||  |  |  |  \   --.
 * `--'`--''--'`--'  `--'`--''--'`--'  `--'   `----'
 *                     ,--.,--.   ,--.   ,--.
 *  ,---.  ,---.,--.--.`--'|  |-. |  |-. |  | ,---.
 * (  .-' | .--'|  .--',--.| .-. '| .-. '|  || .-. :
 * .-'  `)\ `--.|  |   |  || `-' || `-' ||  |\   --.
 * `----'  `---'`--'   `--' `---'  `---' `--' `----'
 * 
 * 
 *  _
 * | |__ _  _
 * | '_ \ || |
 * |_.__/\_, |
 *        |__/    _       _           _
 *      _ __ ___ (_)_ __ (_)_ __ ___ (_)_______ _ __
 *     | '_ ` _ \| | '_ \| | '_ ` _ \| |_  / _ \ '__|
 *     | | | | | | | | | | | | | | | | |/ /  __/ |
 *     |_| |_| |_|_|_| |_|_|_| |_| |_|_/___\___|_|
 * 
 * 
 * @title InfiniteScribbleMinter
 * @author minimizer <[email protected]>; https://minimizer.art/
 * 
 * The Infinite Scribble is abundant, free, and for everyone. These playful digital doodles
 * are here to cheer you up. When you mint, you create a new unique drawing and also extend
 * the collection to help spread the joy. If no one mints for two weeks, the collection
 * closes forever.
 * 
 * In-chain artwork, SVG generated from the smart contract. For a given piece, the artwork
 * can be generated in any aspect ratio (width:height) from 3:1 to 1:3, where width and height
 * are between 1 and 127, via tokenURIAtAspectRatio(). Each token has a default aspect ratio
 * which is used by the standard tokenURI(), which can also be changed by owner of the token
 * via setTokenAspectRatio(). If the aspect ratio is changed, a event is emitted following
 * ERC-4906, which is new, and which hopefully marketplaces support over time.
 * 
 * As a free to mint, infinite supply project, there is room to have some flexibility with
 * mint mechanics. The owner of the contract can vary how many mints/wallets per transaction,
 * and whether the mints must be to the transaction originator or not.
 * 
 * The owner does not have these mint restrictions and can also designate other addresses as
 * 'privledged' so as to also not be restricted. However, any mint from the owner or a
 * privledged address does not extend the minting window.
 * 
 * A snapshotting mechanism is also implemented which gas efficiently remembers which address
 * held each token at the time of a given snapshot. More information in ERC721ASnapshotable.
 * 
 * The contract has royalties implemented via ERC-2981 as well as OpenSea's Operator Filterer.
 * At the time of creation of this contract the NFT environment was in a race to the bottom
 * across marketplaces, with artist royalties as the primary casualty. It's not clear what the
 * eventual solution will be for royalties, but these are the current best options.
 */


contract InfiniteScribbleMinter is DefaultOperatorFilterer, IERC2981, ERC721ASnapshotable, IERC4906A, Ownable {
    
    //The time at which no further mints are allowed
    //This field needs to be continuously extended or otherwise no more mints are allowed
    uint public mintCloseTime;
    
    //This minting contract delegates the art generaton to the contract at this address
    ArtGenerator private _artContract;
    
    //Priviledged minters skip the validation (and can therefore mint many at once) but do not advance
    //the close time. May be used for various ways to do follow-on experiments with this project.
    mapping(address => bool) _priviledgedMinters;
    
    //Settings for minting, either the defaults or temporary overrides will take this shape
    struct MintParameters {
        //setting both to false will pause minting
        bool allowMintToSelf;
        bool allowMintToOthers;
        bool allowMintFromContract;
        
        //per transaction settings
        uint maxAddresses;
        uint maxPerAddress;
    }
    
    //Are the default settings overridden?
    //This can be done within a time window or a mint number window (e.g. tokens 100-120)
    struct OverrideCriteria {
        bool isSet; //is the override set?
        bool isByTime; //is by time? (true) or based on tokenId? (false)
        uint start;
        uint end;
    }
    
    //All the mint settings, publicly exposed
    struct MintSettings {
        MintParameters defaultParameters;
        MintParameters overrideParameters;
        OverrideCriteria overrideCriteria;
    }
    MintSettings public mintSettings;
    
    
    
    //Used for mint() with multiple mints in one transaction
    struct MintTarget {
        address to;
        uint16 num;
    }
    
    //Remember which was the last token to extend the mint in case it is needed in the future.
    //This will be the latest 'non-privledged' mint
    int private _latestTokenToExtendMint = -1;
    uint private _asOfTotalMinted = 0;
    
    
    //Used for remembering the aspect ratio of a given piece
    struct AspectRatio {
        uint8 width;
        uint8 height;
    }
    
    //For gas efficiency of minting, don't actually store the aspect ratio for each token.
    //Instead, any new mints which match the previous most recent aspect ratio look backwards
    //to find the proper aspect ratio at time of rendering in tokenURI()
    BitSequence private _setAspectRatios;
    mapping(uint => AspectRatio) private _aspectRatios;
    
    
    //Who are royalties going to, and how much?
    address private _royaltyRecipient;
    uint16 private _royaltyBasisPoints;

    
    
    
    uint private constant TWO_WEEKS = 2*7*24*60*60;
    
    constructor(ArtGenerator artContract) ERC721ASnapshotable(artContract.name(), artContract.symbol()) {
        _artContract = artContract;
        _royaltyRecipient = owner();
        _royaltyBasisPoints = 500;
        mintSettings.defaultParameters = MintParameters(false, false, false, 1, 1);
        mintSettings.overrideParameters = MintParameters(false, false, false, 1, 1);
        mintSettings.overrideCriteria = OverrideCriteria(false, false, 0, 0);
    }
    
    modifier validToken(uint tokenId) {
        require(_exists(tokenId), 'Invalid tokenId');
        _;
    }
    
    modifier validAspectRatio(uint8 widthRatio, uint8 heightRatio) {
        require(widthRatio > 0 && heightRatio > 0 && uint(widthRatio)*3>=heightRatio && uint(heightRatio)*3>=widthRatio, 'Aspect ratio not between 3:1 and 1:3');
        _;
    }
    
    modifier onlyHolder(uint tokenId) {
        require(msg.sender == ownerOf(tokenId), 'Caller is not holder');
        _;
    }
    
    //Convenience mint method mints only one token to the transaction originator. calls mint()
    function mintOne(uint8 widthRatio, uint8 heightRatio) external payable {
        MintTarget[] memory oneMint = new MintTarget[](1);
        oneMint[0].to=msg.sender;
        oneMint[0].num=1;
        mint(oneMint, widthRatio, heightRatio);
    }
    
    //Complex mint function which can take multiple addresses and different amounts to each address
    //Validates mints and extends the minting window, except for privledged minters where it does neither
    function mint(MintTarget[] memory mints, uint8 widthRatio, uint8 heightRatio) public payable validAspectRatio(widthRatio, heightRatio) {
        require(isMintingOpen(), 'Minting is closed');
        require(mints.length>0, 'No mints requested');
        
        bool privledged = msg.sender == owner() || _priviledgedMinters[msg.sender];
        if(privledged) {
            //if the previous mint wasn't privledged, remember that mint as the latest to extend the window
            if(_asOfTotalMinted != _totalMinted()) {
                _latestTokenToExtendMint = int(_totalMinted()) - 1;
            }
        } else {
            validateMints(currentMintParameters(), mints, msg.sender, tx.origin);
            mintCloseTime = block.timestamp + TWO_WEEKS;
        }
        
        uint nextTokenId = _totalMinted();
        AspectRatio memory latestAspectRatio = _aspectRatios[nextTokenId==0?0:uint(_setAspectRatios.firstSet(nextTokenId))];
        if(latestAspectRatio.width != widthRatio || latestAspectRatio.height != heightRatio) {
            _aspectRatios[nextTokenId] = AspectRatio(widthRatio, heightRatio);
            _setAspectRatios.set(nextTokenId);
        }
        
        for(uint i=0;i<mints.length;i++) {
            _safeMint(mints[i].to, mints[i].num);
        }
        
        if(privledged) {
            //remember the latest privledged mint, for logic above
            _asOfTotalMinted = _totalMinted();
        }
    }
    
    //Checks the mint targets to make sure they would pass the provided minting parameters
    //As a public pure function this can be called directly from a given UI
    //If the target addresses provided in the mints parameter are unique and sorted, validation takes less gas
    function validateMints(MintParameters memory mintParameters, MintTarget[] memory mints, address msgSender, address txOrigin) public pure {
        unchecked {
            require(msgSender == txOrigin || mintParameters.allowMintFromContract, 'Cannot mint from contract');
            
            uint numUniqueAddresses = 0;
            bool sorted = true;
            
            for(uint i=0;i<mints.length;i++) {
                require(mints[i].num > 0, 'Invalid amount');
                if(mints[i].to == txOrigin) {
                    require(mintParameters.allowMintToSelf, 'Cannot mint to self');
                } else {
                    require(mintParameters.allowMintToOthers, 'Cannot mint to others');
                }
                
                uint totalToAddress = mints[i].num;
                bool isUnique = true;
                if(i>0) {
                    sorted = sorted && (mints[i-1].to < mints[i].to);
                    if(!sorted) {
                        for(uint j=0;j<i;j++) {
                            if(mints[j].to==mints[i].to) {
                                totalToAddress += mints[j].num;
                                isUnique = false;
                            }
                        }
                    }
                }
                require(totalToAddress <= mintParameters.maxPerAddress, 'Exceeded max per address');
                if(isUnique) {
                    numUniqueAddresses++;
                }
            }
            require(numUniqueAddresses <= mintParameters.maxAddresses, 'Exceeded max addresses');
        }
    }
    
    //Whether a mint will be allowed based on the close time (other validation rules checked separately)
    function isMintingOpen() public view returns (bool) {
        return mintCloseTime>=block.timestamp || mintCloseTime==0; //0 case is for the initial mint
    }
    
    //Which mint last extended the window (privledged mints are excluded)
    function latestTokenToExtendMint() public view returns (int) {
        return _asOfTotalMinted == _totalMinted() ? _latestTokenToExtendMint : int(_totalMinted()) - 1;
    }
    
    //Set the mint parameters
    function setMintParameters(bool allowMintToSelf, bool allowMintToOthers, bool allowMintFromContract, uint maxAddresses, uint maxPerAddress) external onlyOwner {
        mintSettings.defaultParameters = MintParameters(allowMintToSelf, allowMintToOthers, allowMintFromContract, maxAddresses, maxPerAddress);
    }
    
    //Set the overridden mint parameters and in which window they would apply
    function setOverrideMintParameters(bool allowMintToSelf, bool allowMintToOthers, bool allowMintFromContract, uint maxAddresses, uint maxPerAddress,
                                       bool isByTime, uint start, uint end) external onlyOwner {
        mintSettings.overrideParameters = MintParameters(allowMintToSelf, allowMintToOthers, allowMintFromContract, maxAddresses, maxPerAddress);
        mintSettings.overrideCriteria = OverrideCriteria(true, isByTime, start, end);
    }
    
    //Clear the override, reverting to the default mint parameters
    function clearOverrideMintParameters() external onlyOwner {
        mintSettings.overrideParameters = MintParameters(false, false, false, 0, 0);
        mintSettings.overrideCriteria = OverrideCriteria(false, false, 0, 0);
    }
    
    //Get the current mint parameters, but checking to see if the override criteria apply
    function currentMintParameters() public view returns (MintParameters memory) {
        if(mintSettings.overrideCriteria.isSet && 
           (mintSettings.overrideCriteria.isByTime?block.timestamp:totalSupply())>=mintSettings.overrideCriteria.start &&
           (mintSettings.overrideCriteria.isByTime?block.timestamp:totalSupply())<=mintSettings.overrideCriteria.end) {
            
            return mintSettings.overrideParameters;
        }
        return mintSettings.defaultParameters;
    }
    
    //Designate an address as privledged or not
    function setPriviledgedMinter(address minter, bool isPriviledged) external onlyOwner {
        _priviledgedMinters[minter] = isPriviledged;
    }
    
    
    
    //Exposing snapshot data of ERC721ASnapshotable
    function latestSnapshot() public view returns (uint) {
        return _latestSnapshot();
    }
    
    //Take a snapshot of ownership, exposing method in ERC721ASnapshotable
    function takeSnapshot() public onlyOwner {
        _takeSnapshot();
    }
    
    //Exposing snapshot data of ERC721ASnapshotable
    function snapshotInfo(uint snapshotNumber) public view returns (SnapshotInfo memory) {
        return _snapshotInfo(snapshotNumber);
    }
    
    //Exposing snapshot data of ERC721ASnapshotable
    function snapshotOwnershipOf(uint snapshotNumber, uint tokenId) public view returns (address, uint64) {
        TokenOwnership memory ownership = _snapshotTokenOwnershipOf(snapshotNumber, tokenId);
        return (ownership.addr, ownership.startTimestamp);
    }
    
    //Exposing snapshot data of ERC721ASnapshotable
    function currentOwnershipOf(uint tokenId) public view validToken(tokenId) returns (address, uint64) {
        TokenOwnership memory ownership = _ownershipOf(tokenId);
        return (ownership.addr, ownership.startTimestamp);
    }
    
    //Exposing snapshot data of ERC721ASnapshotable
    function firstOwnershipOf(uint tokenId) public view validToken(tokenId) returns (address, uint64) {
        TokenOwnership memory originalOwnership = _originalTokenOwnershipOf(tokenId);
        if(originalOwnership.addr==address(0)) {
            return currentOwnershipOf(tokenId);
        }
        return (originalOwnership.addr, originalOwnership.startTimestamp);
    }
    
    
    //Token hash is used as an input into the artwork generation
    //It is based on the tokenId, time of mint and original owner of the given token
    function tokenHash(uint tokenId) public view returns (bytes32) {
        (address firstOwnerAddress, uint64 mintTime) = firstOwnershipOf(tokenId);
        return (keccak256(abi.encodePacked(firstOwnerAddress, mintTime, tokenId)));
    }
    
    
    //Get the current token aspect ratio set for a given token
    function tokenAspectRatio(uint tokenId) public view validToken(tokenId) returns (AspectRatio memory) {
        return _aspectRatios[uint(_setAspectRatios.firstSet(tokenId))];
    }
    
    //Set the token aspect ratio set for a given token. This changes what tokenURI() generates
    function setTokenAspectRatio(uint tokenId, uint8 widthRatio, uint8 heightRatio) external onlyHolder(tokenId) validAspectRatio(widthRatio, heightRatio) {
        if(tokenId<_totalMinted()) {
            _aspectRatios[tokenId+1] = _aspectRatios[uint(_setAspectRatios.firstSet(tokenId))];
            _setAspectRatios.set(tokenId+1);
        }
        _aspectRatios[tokenId] = AspectRatio(widthRatio, heightRatio);
        _setAspectRatios.set(tokenId);
        emit MetadataUpdate(tokenId);
    }
    
    function tokenURI(uint tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        AspectRatio memory aspectRatio = tokenAspectRatio(tokenId);
        return tokenURIAtAspectRatio(tokenId, aspectRatio.width, aspectRatio.height);
    }

    function tokenURIAtAspectRatio(uint tokenId, uint8 widthRatio, uint8 heightRatio) public view validAspectRatio(widthRatio, heightRatio) returns (string memory) {
        require(msg.sender == tx.origin); //high gas operation, not meant to be called on chain
        return _artContract.tokenURI(tokenId, tokenHash(tokenId), widthRatio, heightRatio);
    }
    
    
    // Set the royalty amount, specified in basis points
    // All tokens have the same royalty amount
    // Used by ERC-2981 implementation
    // Royalty info can be changed after the contract is frozen
    function setRoyaltyAddressAndBasisPoints(address recipient, uint16 royaltyBasisPoints) external onlyOwner { 
        _royaltyRecipient = recipient;
        _royaltyBasisPoints = royaltyBasisPoints;
    }
    
    
    // Implementation of royaltyInfo for ERC-2981
    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (_royaltyRecipient, (salePrice * _royaltyBasisPoints) / 10000);
    }
    
    // Owner can transfer accumulated funds from contract.
    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    //If someone wants to send funds, they will be accepted
    receive() external payable {}

    // Contract supports ERC-721, ERC-2981 and ERC-4906
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, IERC721A, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId) || type(IERC2981).interfaceId == interfaceId || bytes4(0x49064906) == interfaceId;
    }


    //Implementation for OpenSea's operator filter
    function setApprovalForAll(address operator, bool approved) public override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    
    //Implementation for OpenSea's operator filter
    function approve(address operator, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    
    //Implementation for OpenSea's operator filter
    function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
    
    //Implementation for OpenSea's operator filter
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
    
    //Implementation for OpenSea's operator filter
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}