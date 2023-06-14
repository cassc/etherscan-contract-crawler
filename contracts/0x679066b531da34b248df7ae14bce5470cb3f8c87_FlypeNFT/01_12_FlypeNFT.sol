// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract FlypeNFT is ERC1155, AccessControl {
    /// @notice Last used NFT id 
    uint256 public tokenCounter;
    /// @notice Maximum amount of NFTs
    uint256 public maxSupply;
    /// @notice True if minting is paused 
    bool public onPause;

    string public name = "Flype MULTI-PASS";
    string public symbol = "MULTIPASS";

    /// @notice List of users who can mint
    /// @dev user => isAllowed
    mapping (address => bool) internal _allowList;
    /// @notice List of users who have minted 
    /// @dev user => areadyMinted
    mapping (address => bool) public minted;
    mapping (address => uint256[]) internal _getNFTid;    

    string public baseURI;
    address internal previousContract; 

    /// @notice Restricts from calling function when sale is on pause
    modifier OnPause(){
        require(!onPause, "Mint is on pause");
        _;
    }

    modifier onlyOwner(){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only owner can use this function");
        _;
    }

    constructor (string memory _uri) ERC1155(_uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        baseURI = _uri;
    }

    function setPreviousList(address contractAddress) external onlyOwner(){
        previousContract = contractAddress;
    }

    /// @notice Function that allows contract owner to update maximum supply of NFTs
    /// @param _newMaxSupply new masximum supply of NFTs
    function setMaxSupply(uint _newMaxSupply) external onlyOwner{
        maxSupply = _newMaxSupply;
    }

    /// @notice Function that allows contract owner to pause minting
    /// @param _onPause new state of pause
    function setOnPause(bool _onPause) external onlyOwner{
        onPause = _onPause;
    }

    function setBaseURI(string memory _URI)external onlyOwner{
        baseURI = _URI;
    }   

    /// @notice Function that allows contract owner to give permission to mint NFT for a user
    /// @param allowedUser address of user who whould be addeded to allowlist
    function addToAllowList(address allowedUser) external onlyOwner{
        _addToAllowList(allowedUser);
    }

    /// @notice Function that allows contract owner to give permission to mint NFT for multiple users
    /// @param allowedUsers addresses of users who whould be addeded to allowlist
    function multipleAddToAllowList(address[] memory allowedUsers) external onlyOwner{
        for(uint i; i < allowedUsers.length; i++){
            _addToAllowList(allowedUsers[i]);
        }
    }

    /// @notice Function that allows contract owner to remove permission to mint NFT from a user
    /// @param removedUser address of user who whould be addeded to allowlist
    function removeFromAllowList(address removedUser) external onlyOwner{
        _removeFromAllowList(removedUser); 
    }

    /// @notice Function that allows contract owner to remove permission to mint NFT for multiple users
    /// @param removedUsers addresses of users who whould be removed to allowlist
    function multipleRemoveFromAllowList(address[] memory removedUsers) external onlyOwner{
        for(uint i; i < removedUsers.length; i++){
            _removeFromAllowList(removedUsers[i]);
        }
    }

    function getNFTid(address user) external view returns(uint256[] memory){
        return(_getNFTid[user]);
    }

    /// @notice Function that create new NFT for the caller
    /// @dev Caller must be previously addede to allowlist 
    function mint() public OnPause returns (uint256) {
        require(allowList(_msgSender()), "Only allowed addresses can mint");
        require(!minted[_msgSender()], "Already minted");
        require(tokenCounter < maxSupply, "All NFT's are already minted");
        tokenCounter++;
        uint256 newItemId = tokenCounter;
        minted[_msgSender()] = true;
        _getNFTid[_msgSender()].push(newItemId);
        _mint(_msgSender(), newItemId, 1, new bytes(0));
        emit URI(uri(newItemId), newItemId);
        return newItemId;
    }

    function uri(uint256) override public view returns(string memory){
        return(
            baseURI 
        );
    }

    function allowList(address user) public view returns(bool){
        if(previousContract == address(0)){
            return _allowList[user];
        }
        else{
            return(
                _allowList[user] || FlypeNFT(previousContract).allowList(user) 
            );
        }
    }


    /// @notice Function that give permission to mint NFT for a user
    /// @param allowedUser address of user who whould be addeded to allowlist
    function _addToAllowList(address allowedUser) internal {
        _allowList[allowedUser] = true;
        minted[allowedUser] = false;
    }

    /// @notice Function that remove permission to mint NFT from a user
    /// @param removedUser address of user who whould be addeded to allowlist
    function _removeFromAllowList(address removedUser) internal {
        _allowList[removedUser] = false;
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override{
        revert("Non-transferable");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override{
        revert("Non-transferable");
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }
}