// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/UpdateData.sol";
import "./IInvestment.sol";
import "./IMetadataGeneration.sol";

/** 
* @author Formation.Fi.
* @notice The Implementation of the user's deposit proof token {ERC721}.
*/

contract DepositConfirmation is ERC721, Ownable {
    using Strings for uint256;

    uint256 public tolerance = 1e3; 
    string public baseURI;
    bool public onChainMetaData;
    mapping(address => uint256) private tokenIdPerAddress;
    mapping(address => UpdateData.PendingRequest) public pendingDepositPerAddress;
    mapping(address => UpdateData.Event[]) public pendingDepositPerAddressPerEvent;
    address[] public usersOnPendingDeposit;
    IInvestment public investment;
    IMetadataGeneration public metadataGeneration;
    event MintDeposit(address indexed _address, uint256 _id);
    event BurnDeposit(address indexed _address, uint256 _id);
    event UpdateBaseURI(string _baseURI);
    event UpdateOnChainMetaData(bool _state);

    constructor(string memory _name , string memory _symbol)  
    ERC721 (_name,  _symbol){
    }

    modifier onlyInvestment() {
        require(address(investment) != address(0),
            "Formation.Fi: zero address"
        );
        require(msg.sender == address(investment), 
            "Formation.Fi: not proxy");
        _;
    }
    
    /**
     * @dev get the token id of user's address.
     * @param _account The user's address.
     * @return token id.
    */
    function getTokenId(address _account) external view returns (uint256) {
        require(_account!= address(0),
            "Formation.Fi: zero address"
        );
        return tokenIdPerAddress[_account];
    }

    /**
     * @dev get the number of users.
     * @return number of users.
    */
    function getUsersSize() external view  returns (uint256) {
        return usersOnPendingDeposit.length;
    }
    
    /**
     * @dev get addresses of users on deposit pending.
     * @return  addresses of users.
    */
    function getUsers() external view returns (address[] memory) {
        return usersOnPendingDeposit;
    }

    /**
     * @dev get the total deposit value on pending until the last event.
     * @param _account user's address.
     * @param _indexEvent the index of the next manager validation event.
     * @return _totalValue the total deposit value on pending until the last event.
    */
    function getTotalValueUntilLastEvent(address _account, uint256 _indexEvent) public view 
        returns (uint256 _totalValue){ 
        _totalValue = UpdateData.getTotalValueUntilLastEvent(pendingDepositPerAddressPerEvent[_account],
        _indexEvent);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        if (onChainMetaData){
            return metadataGeneration.render(tokenId);
        }
        else {
            string memory _string = _baseURI();
            return bytes(_string).length > 0 ? string(abi.encodePacked(_string, tokenId.toString())) : "";
        }
    }

    /**
     * @dev update Investment.
     * @param _investment the new Investment.
    */
    function setInvestment(address _investment) external onlyOwner {
        require(_investment != address(0),
            "Formation.Fi: zero address"
        );
        investment = IInvestment(_investment);
    } 

    /**
     * @dev update metadataGeneration.
     * @param _metadataGeneration the new metadataGeneration.
    */
    function setMetadataGeneration(address _metadataGeneration) external onlyOwner {
        require(_metadataGeneration!= address(0),
            "Formation.Fi: zero address");
        metadataGeneration = IMetadataGeneration(_metadataGeneration);
    }   

    /**
     * @dev update the Metadata URI
     * @param _tokenURI the Metadata URI.
    */
    function setBaseURI(string calldata _tokenURI) external onlyOwner {
        baseURI = _tokenURI;
        emit UpdateBaseURI(_tokenURI);
    }

    /**
     * @dev update the tolerance.
     * @param _value the new value of the tolerance.
    */
    function setTolerance(uint256 _value) external onlyOwner {
        tolerance = _value; 
    }

    /**
     * @dev update the variable onChainMetaData.
     * @param  _state true if the metadata are generated onchain, false otherwise.
     * @notice Emits a {UpdateOnChainMetaData} event with `_state`.
    */
    function setOnChainMetaData(bool _state) external onlyOwner {
        require(onChainMetaData != _state, "Formation.Fi: no change");
        onChainMetaData = _state;
        emit UpdateOnChainMetaData(_state);
    }

    /**
     * @dev mint the deposit proof ERC721 token.
     * @notice the user receives this token when he makes 
     * a deposit request.
     * Each user's address can at most have one deposit proof token.
     * @param _account The user's address.
     * @param _tokenId The id of the token.
     * @param _amount The deposit amount in the requested Stablecoin.
     * @param _indexEvent  The index of the manager validation event.
     * @notice Emits a {MintDeposit} event with `_account` and `_tokenId `.
    */
    function mint(address _account, uint256 _tokenId, uint256 _amount, uint256 _indexEvent) 
       external onlyInvestment {
       require (balanceOf(_account) == 0, 
            "Formation.Fi: deposit token exists");
       _safeMint(_account,  _tokenId);
       tokenIdPerAddress[_account] = _tokenId;
       updateDepositData( _account,  _tokenId, _amount,  _indexEvent, true, false);
       emit MintDeposit(_account, _tokenId);
    }

    /**
     * @dev burn the deposit proof ERC721 token.
     * @notice the token is burned  when the manager fully validates
     * the user's deposit request.
     * @param _tokenId The id of the token.
     * @notice Emits a {BurnDeposit} event with `owner` and `_tokenId `.
    */
    function burn(uint256 _tokenId) internal {
        address owner = ownerOf(_tokenId);
        require (pendingDepositPerAddress[owner].state != Data.State.PENDING,
            "Formation.Fi: deposit token on pending");
        _deleteDepositData(owner);
        _burn(_tokenId); 
        emit BurnDeposit(owner, _tokenId);
    }
     
    /**
     * @dev update the user's deposit data.
     * @notice this function is called after each desposit request 
     * by the user or after each validation by the manager.
     * @param _account The user's address.
     * @param _tokenId The depoist proof token id.
     * @param _amount  The deposit amount to be added or removed.
     * @param _indexEvent  The index of the manager validation event.
     * @param _isAddCase  = 1 when the user makes a deposit request.
     * = 0, when the manager validates the user's deposit request.
     * @param _isCancel  = 1  to cancel the deposit request, 0 otherwise.
    */
    function updateDepositData(address _account, uint256 _tokenId, 
        uint256 _amount, uint256 _indexEvent, bool _isAddCase, bool _isCancel) public onlyInvestment {
        require (_exists(_tokenId), 
            "Formation.Fi: no token");
        require (ownerOf(_tokenId) == _account , 
            "Formation.Fi:  not owner");
        if(_amount > 0){
            UpdateData.updatePendingRequestData(pendingDepositPerAddress[_account], 
            pendingDepositPerAddressPerEvent[_account], usersOnPendingDeposit, 
            _account, _amount, _indexEvent, tolerance, _isAddCase,  _isCancel);
        }
        if (! _isAddCase){
            uint256 _newAmount = pendingDepositPerAddress[_account].amount;
            uint256 _tolerance = tolerance;
            if (_isCancel){
                _tolerance = 0;
            }
            if (_newAmount <= tolerance){
                pendingDepositPerAddress[_account].state = Data.State.NONE;
                burn(_tokenId);
                if (_newAmount > 0){
                    investment.updateDepositAmountTotal(_newAmount);
                }
            }
        }
    }
    
    /**
     * @dev delete the user's deposit proof token data.
     * @notice this function is called when the user's deposit request is fully 
     * validated by the manager.
     * @param _account The user's address.
    */
    function _deleteDepositData(address _account) internal {
        require(_account!= address(0),
            "Formation.Fi: zero address"
        );
        uint256 _index = pendingDepositPerAddress[_account].listPointer;
        address _lastUser = UpdateData.deletePendingRequestData(usersOnPendingDeposit, _index);
        pendingDepositPerAddress[_lastUser].listPointer = _index;
        delete pendingDepositPerAddress[_account]; 
        delete tokenIdPerAddress[_account];    
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256,
        uint256
    ) internal virtual override {
        require ((from == address(0)) || (to == address(0)), 
            "Formation.Fi: transfer not allowed");
    }

    /**
     * @dev Get the Metadata URI
    */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
      
}