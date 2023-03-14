// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./ITransfer.sol";


//author = atak.eth
contract DreamGirlsV2 is ERC721AUpgradeable, DefaultOperatorFiltererUpgradeable,
    OwnableUpgradeable {
    
    /*
     PHASE 1: SN + DL
     PHASE 2: WL
    */
    uint256 public phase;

    bool public tradeLock;

    mapping (address => bool) teamMinter;

    uint256 maxSupply;
    string baseURI;

    //Merkle Roots
    bytes32 SNroot;
    bytes32 DLroot;
    bytes32 WLroot;

    //Minted by wallet for each phase
    mapping (address => uint256) public SNMinted;
    mapping (address => uint256) public DLMinted;
    mapping (address => uint256) public WLMinted;

    
    function initialize(string memory name, string memory symbol) initializerERC721A initializer public {

        maxSupply = 20000;
        tradeLock = true;
        
        __ERC721A_init(name, symbol);
        __Ownable_init();
        __DefaultOperatorFilterer_init();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function transferERC20(address _tokenContract, address _to, uint256 _quantity) external onlyOwner{
        require(ITransfer(_tokenContract).transfer(_to, _quantity),"Tx gives error");
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.setControllerAddress(newOwner);
        super.transferOwnership(newOwner);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        require(!tradeLock, "Trade lock is on");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        require(!tradeLock, "Trade lock is on");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        require(!tradeLock,"Trade lock is on");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        require(!tradeLock,"Trade lock is on");
        super.approve(operator, tokenId);
    }

    function addTeamMinter(address[] memory _newMinterAddresses) public onlyOwner{

        for(uint i = 0; i < _newMinterAddresses.length; ){

            teamMinter[_newMinterAddresses[i]] = true;

            unchecked {
                ++i;
            }
        }
    }

    function removeTeamMinter(address[] memory _removeMinterAddresses) public onlyOwner{

        for(uint i = 0; i < _removeMinterAddresses.length; ){

            teamMinter[_removeMinterAddresses[i]] = false;

            unchecked {
                ++i;
            }
        }
    }

    function setSNRoot(bytes32 _newRoot) public onlyOwner{
        SNroot = _newRoot;
    }

    function setDLRoot(bytes32 _newRoot) public onlyOwner{
        DLroot = _newRoot;
    }

    function setWLRoot(bytes32 _newRoot) public onlyOwner{
        WLroot = _newRoot;
    }

    function setAllRoots(bytes32 _newSNRoot, bytes32 _newDLRoot, bytes32 _newWLRoot) external onlyOwner{
        setSNRoot(_newSNRoot);
        setDLRoot(_newDLRoot);
        setWLRoot(_newWLRoot);
    }

    function verify(bytes32 root, bytes32[] calldata merkleProof, address wallet, uint256 allowance) internal pure returns(bool){
        bytes32 node = keccak256(abi.encodePacked(wallet, allowance));
        return MerkleProof.verify(merkleProof, root, node);
    }

    function phaseSwitch(uint256 newPhase) external onlyOwner{
        phase = newPhase;
    }

    function tradeLockSwitch() external onlyOwner{
        tradeLock = !tradeLock;
    }

    function mint(bytes32[] calldata merkleProof, uint256 allowance, uint256 quantity) external payable{
        require(totalSupply() + quantity <= maxSupply, "This tx would exceed max supply");

        if(phase == 1){

            if(verify(SNroot, merkleProof, msg.sender, allowance)){
                require(quantity <= allowance - SNMinted[msg.sender], "This exceeds max amount for this wallet");
                SNMinted[msg.sender] += quantity;
            }else if(verify(DLroot, merkleProof, msg.sender, allowance)){
                require(quantity <= allowance - DLMinted[msg.sender], "This exceeds max amount for this wallet");
                require(msg.value >=  0.069 ether * quantity, "Not enough funds sent");
                DLMinted[msg.sender] += quantity;
            }else{
                revert("Merkle Proof invalid");
            }

        }else if(phase == 2){

            require(msg.value >=  0.069 ether * quantity, "Not enough funds sent");

            if(verify(DLroot, merkleProof, msg.sender, allowance)){
                require(quantity <= allowance - DLMinted[msg.sender], "This exceeds max amount for this wallet");
                DLMinted[msg.sender] += quantity;
            }else if(verify(WLroot, merkleProof, msg.sender, allowance)){
                require(quantity <= allowance - WLMinted[msg.sender], "This exceeds max amount for this wallet");
                WLMinted[msg.sender] += quantity;                
            }else{
                revert("Merkle Proof invalid");
            }
                            
        }else{ 
            revert("The sale hasn't started yet");
        }

        _mint(msg.sender, quantity);
    }

    function teamMint(uint256 quantity) external{
        require(teamMinter[msg.sender], "This wallet is not a part of the team");
        require(totalSupply() + quantity <= maxSupply, "This tx would exceed max supply");
        _mint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner{
        require(address(this).balance > 0, "No balance to withdraw");
        payable(msg.sender).transfer(address(this).balance); 
    }

    function burnToken(uint256[] calldata tokenIDs) external{
        for(uint i; i < tokenIDs.length;){
            _burn(tokenIDs[i]);

            unchecked{
                ++i;
            }
        }
    }

}