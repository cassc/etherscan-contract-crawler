// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol"; // Multi-asset
import "@openzeppelin/contracts/token/common/ERC2981.sol"; // Royalties
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // ERC20 currencies
import "@openzeppelin/contracts/access/AccessControl.sol"; // Roles
import "operator-filter-registry/src/DefaultOperatorFilterer.sol"; // OpenSea Creator Fee Enforcement

/**
 * @title Wildbots
 * @author Mainbot
 *
 * @notice You can only use this contract to mint Wildbots NFTs.
 * @dev ERC1155 contract that has create and mint functionality, and supports useful standards from OpenZeppelin,
 * like _exists(), name(), symbol()
 */
contract Wildbots is ERC1155, ERC2981, Ownable, AccessControl, DefaultOperatorFilterer {
   
    string public name;
    string public symbol;
    string private apiURL;

    struct Token {
        uint256 id;
        string uri;
        uint256 maxSupply;
        uint256 totalSupply;
    }   
   
    // Tokens 
    mapping(uint256 => Token) private tokens;

    // Events
    event TokenLaunch(uint256 indexed tokenId, string uri, uint256 maxSupply);

    // Define access control roles
    bytes32 private constant ADMIN  = keccak256("ADMIN_ROLE");

    // Default Royalties
    RoyaltyInfo private defaultRoyaltyInfo;

    /**
     * @dev we don't use the "uri_" param in the ERC1155 constructor as there are known limitations for IPFS metadata.
     * See https://forum.openzeppelin.com/t/how-to-erc-1155-id-substitution-for-token-uri/3312/24 for more details.
     * 
     * @param _name should be "The Wildbots"
     * @param _symbol should be "WLDBOT"
     */
    constructor (
        string memory _name,
        string memory _symbol,
        string memory _apiURL
    )
    ERC1155("")
    {
        name = _name;
        symbol = _symbol;
        apiURL = _apiURL;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
        setDefaultRoyalty(msg.sender , 250);
    }

    
    function launchToken(
        uint256 _tokenId,
        uint256 _maxSupply,
        string calldata _uri
    )
        public
        onlyRole(ADMIN)
    {
        require(tokens[_tokenId].id == 0, "Wildbots: Token already exists");
        require(_tokenId > 0, "Wildbots: Invalid token ID");
        tokens[_tokenId] = Token(_tokenId, _uri, _maxSupply, 0);
        emit TokenLaunch(_tokenId, _uri, _maxSupply);
    }

    function launchTokenBatch(
        uint256[] calldata _tokenIds,
        uint256[] calldata _maxSupplies,
        string[] calldata _uri
    )
        external
        onlyRole(ADMIN)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            launchToken(_tokenIds[i], _maxSupplies[i], _uri[i]);
        }
    }

    function mint(
        address _to,
        uint256 _amount,
        uint256 _tokenId
    )
        external
        onlyRole(ADMIN)
    {
        beforeMint( _tokenId, _amount);
        _mint(_to, _tokenId, _amount, '');
    }


    function mintBatch(
        address[] calldata _tos,
        uint256[] calldata _amounts,
        uint256[] calldata _tokenIds
    )
        external
        onlyRole(ADMIN)
    {
        require(_tos.length == _amounts.length, "Wildbots: _tos and _amounts length mismatch");
        require(_tos.length == _tokenIds.length, "Wildbots: _tos and _tokenIds length mismatch");
        for (uint256 i = 0; i < _tos.length; i++) {
            beforeMint(_tokenIds[i], _amounts[i]);
            _mint(_tos[i], _tokenIds[i], _amounts[i], '');
        }
    }

    /* TOKEN GETTERS & SETTERS */

    function setToken(uint256 _tokenId, uint256 _maxSupply, uint256 _totalSupply, string memory _uri) external onlyRole(ADMIN) {
            tokens[_tokenId].maxSupply = _maxSupply;
            tokens[_tokenId].totalSupply = _totalSupply;
            tokens[_tokenId].uri = _uri;
    }

    function setMaxSupply(uint256 _tokenId, uint256 _maxSupply) external onlyRole(ADMIN) {
        tokens[_tokenId].maxSupply = _maxSupply;
    }

    function setTotalSupply(uint256 _tokenId, uint256 _totalSupply) external onlyRole(ADMIN) {
        tokens[_tokenId].totalSupply = _totalSupply;
    }

    function setUri(uint256 _tokenId, string memory _uri) external onlyRole(ADMIN) {
        tokens[_tokenId].uri = _uri;
    }

    /* TOKEN DETAILS */
    
    function getTokenSupply(uint256 _tokenId) external view returns (uint256 totalSupply, uint256 maxSupply ) {
        return(tokens[_tokenId].totalSupply, tokens[_tokenId].maxSupply);
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
       return string.concat(apiURL, tokens[_tokenId].uri);
    }

    function getApiURL() external view returns (string memory) {
        return apiURL;
    }

    function setApiURL(string memory _apiUrl) external onlyRole(ADMIN){
        apiURL = _apiUrl;
    }

    /* TOKEN ROYALTIES */

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyRole(ADMIN) {
        defaultRoyaltyInfo = RoyaltyInfo(_receiver, _feeNumerator);
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function getDefaultRoyalty() public view returns(RoyaltyInfo memory) {
        return defaultRoyaltyInfo;
    }

    function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) public onlyRole(ADMIN) {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function getTokenRoyalty(uint256 _tokenId) public view returns(address, uint256) {
        return royaltyInfo(_tokenId,  _feeDenominator());
    }

    /* UTILS */

    /**
     *  For every token we mint, we run verifications and store the token details
     */
     function beforeMint(uint256 _tokenId, uint256 _amount) internal {
        string memory status = _getClaimIneligibilityReason(_tokenId, _amount);
        require(keccak256(bytes(status)) == keccak256(bytes("")), status);
        tokens[_tokenId].totalSupply += _amount;
    }
    
    /**
     *  Verifications to run before minting a token to optimise gas
     */
    function _getClaimIneligibilityReason(
        uint256 _tokenId,
        uint256 _amount
    ) internal view returns (string memory) {
            /* Check supply compliance */
        if (_amount <= 0) {
            return "Invalid mint amount";
        }

        if (tokens[_tokenId].totalSupply + _amount > tokens[_tokenId].maxSupply) {
            return "Max supply exceeded";
        }
        
        return "";
    }


    /* MANDATORY OVERRIDEN FUNCTIONS */

    // Mandatory OpenSea overridings to allow creator fee enforcement (see https://github.com/ProjectOpenSea/operator-filter-registry#creator-fee-enforcement )
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981, AccessControl) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId 
        || interfaceId == type(IERC1155MetadataURI).interfaceId
        || interfaceId == type(IERC2981).interfaceId  
        || super.supportsInterface(interfaceId);
    }

    /* ADMIN CAN WITHDRAW FUNDS */
    function withdraw(address[] calldata _addresses) public onlyRole(ADMIN) {
        bool noFunds = true;
        for (uint256 i = 0; i < _addresses.length; i++) {
            // Use address(0) to withdraw ETH
            if (_addresses[i] == address(0)) {
                uint256 ethBalance = address(this).balance;
                if (ethBalance > 0) {
                    payable(msg.sender).transfer(ethBalance);
                    noFunds = false;
                }
            } else {
                uint256 erc20Balance = IERC20(_addresses[i]).balanceOf(address(this));
                if (erc20Balance > 0) {
                    IERC20(_addresses[i]).transfer(msg.sender, erc20Balance);
                    noFunds = false;
                }
            }
        }
        require(!noFunds, "Nothing to withdraw");
    }
}