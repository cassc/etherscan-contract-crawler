// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// simple ownership check, ownership transfer + noContracts modifier 
import {SecuredBase} from "../src/base/SecuredBase.sol";

// https://github.com/chiru-labs/ERC721A
import {ERC721AQueryable, ERC721A} from "../src/erc721a/extensions/ERC721AQueryable.sol";

// https://github.com/fx-portal
import {FxBaseRootTunnel} from "../src/fx-portal/tunnel/FxBaseRootTunnel.sol";

contract Tentacular is ERC721AQueryable, SecuredBase, FxBaseRootTunnel {
    event RequestSend(string cmd, address wallet, uint[] tokenIds);

    bytes32 public constant BOUND = keccak256("BOUND");
    bytes32 public constant UNBOUND = keccak256("UNBOUND");

    uint constant MAX_SUPPLY = 5556;

    address salesContractAddress;

    string baseURI;

    bool public bondsEnabled;

    error MaxSupplyReached();
    error NotSalesContract();
    error BondsDisabled();
    error AlreadyBound(uint tokenId);
    error NotBound(uint tokenId);
    error NotAnOwner();

    mapping(uint => bool) public tokenIdToBound;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        string memory name,
        string memory symbol
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) ERC721A(name, symbol) {}

    ////////////////////////////////////////////////////////////////////////////////
    //// USER ACTIONS
    ////////////////////////////////////////////////////////////////////////////////

    /** 
    @dev mint amount of tokens to wallet
    @notice can be called from the sales contract only
    @param wallet wallet to receive tokens
    @param amount of tokens to be minted
    */
    function mint(address wallet, uint amount) external salesContractOnly {
        if (_totalMinted() + amount > MAX_SUPPLY) revert MaxSupplyReached();

        _mint(wallet, amount);
    } 

    /** 
    @dev bound the specified tokens to BerryJuicer
    @notice can be called when bondsEnabled only, sends the request via bridge to Polygon network 
    @param tokenIds tokens to be bound
    */
    function bound(uint[] calldata tokenIds) external onlyBondsEnabled noContracts {
        for (uint i;i<tokenIds.length;i++) {
            if (ownerOf(tokenIds[i])!=msg.sender) revert NotAnOwner();
            if (tokenIdToBound[tokenIds[i]]) revert AlreadyBound(tokenIds[i]);

            tokenIdToBound[tokenIds[i]]=true;
        }

        bytes memory message = abi.encode(BOUND, abi.encode(msg.sender, tokenIds));
        emit RequestSend("BOUND", msg.sender, tokenIds);
        _sendMessageToChild(message);
    }

    /** 
    @dev unbound the specified tokens from BerryJuicer
    @notice sends the request via bridge to Polygon network 
    @param tokenIds tokens to be unbound
    */
    function unbound(uint[] calldata tokenIds) external noContracts {
        for (uint i;i<tokenIds.length;i++) {
            if (ownerOf(tokenIds[i])!=msg.sender) revert NotAnOwner();
            if (tokenIdToBound[tokenIds[i]]==false) revert NotBound(tokenIds[i]);

            tokenIdToBound[tokenIds[i]]=false;
        }

        bytes memory message = abi.encode(UNBOUND, abi.encode(msg.sender, tokenIds));
        emit RequestSend("UNBOUND", msg.sender, tokenIds);
        _sendMessageToChild(message);
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// OWNER ONLY
    ////////////////////////////////////////////////////////////////////////////////

    /** 
    @dev set the base address for token URI
    @param URI base URI to use
    */
    function setBaseTokenURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    /** 
    @dev set the sales contract address
    @notice used for salesContractOnly modifier checks
    @param _salesContractAddress sales contract address
    */
    function setSalesContract(address _salesContractAddress) external onlyOwner {
        salesContractAddress=_salesContractAddress;
    }

    /** 
    @dev set the bound function status
    @param status true to turn it on, false to turn it off
    */
    function setBondsEnabled(bool status) external onlyOwner {
        bondsEnabled=status;
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// OVERRIDES
    ////////////////////////////////////////////////////////////////////////////////


    /** 
    @dev handle message from the bridge
    @notice not used, the polygon contract connected send no messages
    @param message message to be handled
    */
    function _processMessageFromChild(bytes memory message) internal override {
        // Not used
    }

    /** 
    @dev set child tunnel address
    @notice override to keep the possibility to change it anytime
    @param _fxChildTunnel child tunnel address
    */
    function setFxChildTunnel(address _fxChildTunnel) public virtual override onlyOwner {
        fxChildTunnel = _fxChildTunnel;
    }

    /** 
    @dev returns the baseURI
    @notice override to return variable we can change in setBaseTokenURI
    */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /** 
    @dev called before token is transfered, minted or burned
    @notice override to unbound token automatically during the transfer
    */
    function _beforeTokenTransfers(
        address from,
        address, // to,
        uint256 startTokenId,
        uint256  // quantity
    ) internal virtual override {
        if (tokenIdToBound[startTokenId]) {
            tokenIdToBound[startTokenId] = false;
            uint[] memory tokens = new uint[](1);
            tokens[0]=startTokenId;

            bytes memory message = abi.encode(UNBOUND, abi.encode(from, tokens));
            emit RequestSend("UNBOUND", from, tokens);
            _sendMessageToChild(message);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// MODIFIERS
    ////////////////////////////////////////////////////////////////////////////////

    /** 
    @dev allow method to be executed only if bondsEnabled
    */
    modifier onlyBondsEnabled() {
        if (!bondsEnabled) revert BondsDisabled();
        _;
    }

    /** 
    @dev allow method to be executed only if caller is salesContract
    */
    modifier salesContractOnly() {
        if (msg.sender!=salesContractAddress) revert NotSalesContract();
        _;
    }
}