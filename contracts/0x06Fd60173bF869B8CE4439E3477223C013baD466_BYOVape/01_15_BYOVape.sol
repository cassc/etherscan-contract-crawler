// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./TokenInterface.sol";

contract BYOVape is ERC1155Supply, ERC1155Burnable, Ownable {

    using Counters for Counters.Counter;

    struct BYOVapeData {
        bool isCollectingOpen;                                                       
        uint256 mintPrice;                              
        uint256 maxPerTx;                               
        string uriCharged;
        string uriDischarged;                                 
        address redeemableAddress;                      
        bytes32 merkle;                                 
        bool isWhitelistBased;
        bool podsCharged;                    
        bool enforceBalance;                            
        address linkedAsset;    
        mapping (address => uint256) claims;                        
    }

    string m_Name;
    string m_Symbol;
    mapping(uint256 => BYOVapeData) m_byoVapes;
    Counters.Counter m_vapeCounter; 

    constructor(string memory _name, string memory _symbol) ERC1155("") {
        m_Name =_name;
        m_Symbol = _symbol;
    }

    /*
       PUBLIC, EXTERNAL METHODS
    */

    function publicCollect (
        uint256 _numVapes,
        uint256 _vapeIdx
    ) public payable {
        require (m_byoVapes[_vapeIdx].isCollectingOpen, "Collecting not open yet for this vape.");           
        require (m_byoVapes[_vapeIdx].isWhitelistBased == false, "Vape is whitelist based.");              
        require (m_byoVapes[_vapeIdx].maxPerTx == 0 || _numVapes <= m_byoVapes[_vapeIdx].maxPerTx, "Tx max.");               
        if (m_byoVapes[_vapeIdx].mintPrice > 0 && msg.value < _numVapes * m_byoVapes[_vapeIdx].mintPrice) {
            revert ("Ethereum sent not sufficient.");
        }
        _mint(msg.sender, _vapeIdx, _numVapes, "");
    }

    function whitelistCollect (uint256 _numVapes,
        uint256 _vapeIdx,
        uint256 _merkleIdx,
        uint256 _maxAmount,
        bytes32[] calldata merkleProof) public payable {
            require (m_byoVapes[_vapeIdx].isCollectingOpen, "Collecting not open yet for vape.");            
            if (m_byoVapes[_vapeIdx].mintPrice > 0 && msg.value < _numVapes * m_byoVapes[_vapeIdx].mintPrice) {     
                revert ("Ethereum sent not sufficient.");
            }
            require (m_byoVapes[_vapeIdx].maxPerTx == 0 || _numVapes <= m_byoVapes[_vapeIdx].maxPerTx, "Tx max.");                

            bytes32 nHash = keccak256(abi.encodePacked(_merkleIdx, msg.sender, _maxAmount));
            require(
                MerkleProof.verify(merkleProof, m_byoVapes[_vapeIdx].merkle, nHash),
                "Invalid merkle proof !"
            );
            require(_maxAmount == 0 || m_byoVapes[_vapeIdx].claims[msg.sender] + _numVapes <= _maxAmount, "Minting more than available mints.");

            if (m_byoVapes[_vapeIdx].enforceBalance) {
                TokenInterface token = TokenInterface(m_byoVapes[_vapeIdx].linkedAsset);
                uint256 bal = token.balanceOf(msg.sender);
                require (m_byoVapes[_vapeIdx].claims[msg.sender] + _numVapes <= bal, "Linked asset contract, not enough balance.");  
            }

            _mint(msg.sender, _vapeIdx, _numVapes, "");
            m_byoVapes[_vapeIdx].claims[msg.sender] = m_byoVapes[_vapeIdx].claims[msg.sender] + _numVapes;
    } 

    /*
        VIEWS
    */

    function claimed (uint256 _vapeIdx, address _address) public view returns (uint256) {
        return m_byoVapes[_vapeIdx].claims[_address];
    }

    function isCollectingOpen (uint256 _vapeIdx) public view returns (bool) {
        return m_byoVapes[_vapeIdx].isCollectingOpen;
    }

    function name() public view returns (string memory) {
        return m_Name;
    }

    function symbol() public view returns (string memory) {
        return m_Symbol;
    }      

    /*
        OWNER ONLY
    */

    function createBYOVape(
        bytes32 _merkle,
        bool _isWhitelistBased,
        bool _enforceBalance,
        uint256  _mintPrice, 
        uint256 _maxPerTx,
        string memory _uriCharged,
        string memory _uriDischarged,
        bool _podsCharged,    
        address _redeemableAddress,
        address _linkedAsset
    ) public onlyOwner {
        BYOVapeData storage byoVape = m_byoVapes[m_vapeCounter.current()];
        byoVape.merkle = _merkle;
        byoVape.isCollectingOpen = false;
        byoVape.isWhitelistBased = _isWhitelistBased;
        byoVape.enforceBalance = _enforceBalance;
        byoVape.mintPrice = _mintPrice;
        byoVape.maxPerTx = _maxPerTx;
        byoVape.uriCharged = _uriCharged;
        byoVape.uriDischarged = _uriDischarged;
        byoVape.redeemableAddress = _redeemableAddress;
        byoVape.linkedAsset = _linkedAsset;
        byoVape.podsCharged = _podsCharged;
        m_vapeCounter.increment();
    }

    function editBYOVape(
        bytes32 _merkle,
        bool _isWhitelistBased,
        bool _enforceBalance,
        uint256  _mintPrice, 
        uint256 _maxPerTx,
        address _redeemableAddress,
        address _linkedAsset,
        uint256 _vapeIdx
    ) public onlyOwner {
        m_byoVapes[_vapeIdx].merkle = _merkle;
        m_byoVapes[_vapeIdx].isWhitelistBased = _isWhitelistBased;
        m_byoVapes[_vapeIdx].enforceBalance = _enforceBalance;
        m_byoVapes[_vapeIdx].mintPrice = _mintPrice; 
        m_byoVapes[_vapeIdx].maxPerTx = _maxPerTx;    
        m_byoVapes[_vapeIdx].redeemableAddress = _redeemableAddress;  
        m_byoVapes[_vapeIdx].linkedAsset = _linkedAsset;
    }   

    function rechargePod (uint256 _vapeIdx) public onlyOwner {
        m_byoVapes[_vapeIdx].podsCharged = true;
    }

    function dischargePod (uint256 _vapeIdx) public onlyOwner {
        m_byoVapes[_vapeIdx].podsCharged = false;
    }

    function updateBaseURIs (uint256 _vapeIdx, string memory _chargedURI, string memory _emptyURI) public onlyOwner {
        m_byoVapes[_vapeIdx].uriCharged = _chargedURI;
        m_byoVapes[_vapeIdx].uriDischarged = _emptyURI;
    }

    function toggleCollecting (uint256 _vapeIdx) public onlyOwner {
        m_byoVapes[_vapeIdx].isCollectingOpen = !m_byoVapes[_vapeIdx].isCollectingOpen;
    }

    function mintVapes(uint256 _vapeIdx, address[] calldata to, uint256[] calldata amounts) public onlyOwner {
        require (to.length == amounts.length, "Lengths have to match.");
        for(uint256 i = 0; i < to.length; i++) {           
            _mint(to[i], _vapeIdx, amounts[i], "");
        }
    }

    function withdrawAmount(address payable _to, uint256 _amount) public onlyOwner
    {
        _to.transfer(_amount);
    }

    /*
        OVERRIDES
    */

    function uri(uint256 _id) public view virtual override returns (string memory) {
        require (totalSupply(_id) > 0, "Non-existent token.");
        return m_byoVapes[_id].podsCharged ? m_byoVapes[_id].uriCharged : m_byoVapes[_id].uriDischarged;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }  

    /*
        EXTERNAL
    */

    function burnFromRedeem(
        address _account, 
        uint256 _vapeIdx, 
        uint256 _amount
    ) external {
        require(m_byoVapes[_vapeIdx].redeemableAddress == msg.sender, "Redeemable address only.");
        _burn(_account, _vapeIdx, _amount);
    }  
    
}