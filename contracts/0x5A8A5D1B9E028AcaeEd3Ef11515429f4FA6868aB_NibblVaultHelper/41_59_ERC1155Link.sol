// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import { ERC1155SupplyUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { NibblVault } from "./NibblVault.sol";
import { NibblVaultFactory } from "./NibblVaultFactory.sol";
import { ERC1155 } from "solmate/src/tokens/ERC1155.sol";

contract ERC1155Link is ERC1155, Initializable {

    event TierAdded(uint256 indexed tier, uint256 indexed mintRatio, uint256 indexed maxCap, uint256 userCap );
    event Wrapped(uint256 indexed amount, uint256 indexed tokenID, address indexed to );
    event UnWrapped(uint256 indexed amount, uint256 indexed tokenID, address indexed to );

    NibblVaultFactory private immutable factory; // Factory
    
    NibblVault public linkErc20; // Fractionalised Token

    mapping ( uint256 => string ) private _uri; // Metadata TokenURI  
    mapping ( uint256 => uint256 ) public mintRatio; // Number of ERC20s required for each ERC1155 tokenID
    mapping ( uint256 => uint256 ) public userCap; // max erc1155 for a tokenID a user can mint
    mapping ( uint256 => mapping(address => uint256) ) public userMint; // amt of ERC1155 tokens for a tokenID minted by users (tokenID => (Address => amt))
    mapping ( uint256 => uint256 ) public maxCap; // max erc1155s for a tokenID that can be minted
    mapping ( uint256 => uint256 ) public totalSupply; // totalSupply minted or burned for each tokenID


    /// @notice To check if system isn't paused
    /// @dev pausablity implemented in factory
    modifier whenNotPaused() {
        require(!factory.paused(), 'ERC1155Link: Paused');
        _;
    }

    /// @notice Checks if tier corresponding to _id has been added by curator
    /// @dev as mintRatio of a initialized tier can't be 0, the condition should hold true
    /// @param _id tokenID of tier
    modifier isValidTokenID(uint256 _id) {
        require(mintRatio[_id] > 0, "ERC1155Link: !TokenID");
        _;
    }

    constructor (address payable _factory) {
        factory = NibblVaultFactory(_factory);
        _disableInitializers();
    }

    /// @notice Initializer function for proxy
    function initialize() external initializer {
        linkErc20 = NibblVault(payable(msg.sender));
    }

    /// @notice Adds a tier for the token
    /// @param _maxCap Max Supply of tokens that can be minted for the tokenID
    /// @param _userCap Max Supply of tokens a user cna mint
    /// @param _mintRatio Number of ERC20s required for a tokenID
    /// @param _tokenID tokenID to start tier on
    /// @param _tokenURI MetaData URI for a new tier

    function addTier(uint256 _maxCap, uint256 _userCap, uint256 _mintRatio, uint256 _tokenID, string calldata _tokenURI) external {
        require(msg.sender == NibblVault(linkErc20).curator(),  "ERC1155Link: Only Curator");
        require(mintRatio[_tokenID] == 0,   "ERC1155Link: Tier Exists");
        require(_mintRatio != 0,    "ERC1155Link: !Ratio");
        _uri[_tokenID] = _tokenURI;
        mintRatio[_tokenID] = _mintRatio;
        maxCap[_tokenID] = _maxCap;
        userCap[_tokenID] = _userCap;
        emit TierAdded(_tokenID, _mintRatio, _maxCap, _userCap);
    }


    /// @notice Wraps ERC20 to ERC1155
    /// @param _amount _number of ERC1155 to mint
    /// @param _tokenID tier to wrap on
    /// @param _to address to recieve ERC1155
    function wrap(uint256 _amount, uint256 _tokenID, address _to) external whenNotPaused isValidTokenID(_tokenID) {
        totalSupply[_tokenID] += _amount;
        userMint[_tokenID][msg.sender] += _amount;
        require(totalSupply[_tokenID] <= maxCap[_tokenID], "ERC1155Link: !MaxCap");
        require(userMint[_tokenID][msg.sender] <= userCap[_tokenID], "ERC1155Link: !UserCap");
        linkErc20.transferFrom(msg.sender, address(this), _amount * mintRatio[_tokenID]);
        _mint(_to, _tokenID, _amount, "0");
        emit Wrapped(_amount, _tokenID, _to);
    }

    /// @notice Unwraps ERC1155 to ERC20
    /// @param _amount _amount of erc1155s to unwrap
    /// @param _tokenID tier of token to unwrap
    /// @param _to address to recieve unwrapped tokens
    function unwrap(uint256 _amount, uint256 _tokenID, address _to) external whenNotPaused {
        totalSupply[_tokenID] -= _amount;
        _burn(msg.sender, _tokenID, _amount);
        linkErc20.transfer(_to, _amount * mintRatio[_tokenID]);
        emit UnWrapped(_amount, _tokenID, _to);
    }

    function uri(uint256 _tokenID) public view override returns(string memory) {
        return _uri[_tokenID];
    }

}