// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


/*///////////////////////////////////////////////////////////////////
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|__
_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
*/////////////////////////////////////////////////////////////////////


import './ERC721A.sol';
import './IERC721A.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @author cry (https://twitter.com/cryethereum)
/// @title KeenVerse.sol
contract KeenVerse is ERC721A, Ownable {
    
    using Strings for uint256;

    /// @notice 50 + 171 + 1 is 222, maxSupply
    /// @param _phases array to be set with respective value of _supply
    /// @dev Maps the _phases current index to the same _supply index, resulting in phase:supply association
    /// @dev Mints first token ID (0) to admin, this is the reserved token for keeny.
    /// @dev Sets current phase to first value in array
    
    constructor(uint8[] memory _phases, uint256[] memory _supply, uint64 _maxSupply, string memory _setbaseURI) ERC721A("KeenVerse Genesis", "KeenVerse Genesis"){
        
        setPhaseInformation(_phases, _supply);
        setPhase(_phases[0]);

        _mint(msg.sender, 1);

        maxSupply = _maxSupply;
        URI_BASE = _setbaseURI;
    }

    ////////////////////////////
    // Type: Variables & Misc //
    ////////////////////////////


    mapping (address => uint8) public authorizationList;
    mapping (uint8 => uint256) public phaseSupply;


    /// vars stacked into one slot
    uint64 public maxSupply;
    uint64 public maxPerWallet = 1;
    uint8 public mintPhase;
    
    bool public keenverseEnabled = false;

    string public URI_BASE;

    address public KeenLand;

    error keenverseClosed();
    error maxTotalKeeny();
    error maxPhaseKeeny();
    error notKeenlist();
    error cryAIO();
    error nonExistentTokenID();



    //////////////////////////////////////////////////
    // Type: Utility // Auth: Admin //
    //////////////////////////////////////////////////

    /// @dev Flipsale function inverts boolean value of keenverseEnabled
    function enableKeenverse() 
        public 
        onlyOwner 
    {
        keenverseEnabled = !keenverseEnabled;
    }

    modifier keenyVerseAvailable() {
        if (!keenverseEnabled) revert keenverseClosed();
        _;
    }

    ///////////////////////////////////////////
    // Type: Minting // Auth: Fnf, Whitelist //
    ///////////////////////////////////////////

    /// @dev Mint function, hardcoded 1 per, maxPhaseSupply, Authorization, and tx.origin checks.
    /// @notice Only public function used to execute the mint.
    function enterKeenverse() 
        public 
        keenyVerseAvailable() 
    {
        
        if (totalSupply() >= maxSupply) revert maxTotalKeeny();
        if (phaseSupply[mintPhase] == 0) revert maxPhaseKeeny();
        if (authorizationList[msg.sender] != mintPhase) revert notKeenlist();
        if (tx.origin != msg.sender) revert cryAIO();
        
        _mint(msg.sender, 1);

        /// @dev reset auth list to 0, not able to remint
        /// @dev decrement phaseSupply
        authorizationList[msg.sender] = 0;
        --phaseSupply[mintPhase];
    }
    
    //////////////////////////////
    // Type: URI // Auth: Admin //
    //////////////////////////////
    
    function setURI(string memory _URI_BASE)
        external 
        onlyOwner 
    {
        URI_BASE = _URI_BASE;
    }


    function _baseURI() 
        internal 
        view 
        override 
        returns 
        (string memory) 
    {
        return URI_BASE;
    }

    function tokenURI(uint256 _tokenID) 
        public 
        view 
        override 
        returns 
    (string memory) {
        if (!_exists(_tokenID)) revert nonExistentTokenID();
        return string(abi.encodePacked(_baseURI(), _tokenID.toString(), ".json"));
    }


    //////////////////////////////////////
    // Type: Mint Auth // Auth: Admin //
    //////////////////////////////////////


    /// @notice Addresses can be set according to phase 1 (FnF), or phase 2 (Whitelist), or removed setting phase to 0; 
    /// @param _authAddresses feed address to respective phase
    function setPhaseAuthList(address[] memory _authAddresses, uint8 _phase) 
        public 
        onlyOwner 
    {
        for (uint256 i = 0; i < _authAddresses.length;) {
            authorizationList[_authAddresses[i]] = _phase;
            unchecked { ++i; }
        }
    }

    function setPhaseInformation(uint8[] memory _phases, uint256[] memory _supply) 
        public 
        onlyOwner 
    {
        require(_phases.length == _supply.length, "@dev: incorrect length");
        for (uint256 i = 0; i < _phases.length;) {
            phaseSupply[_phases[i]] = _supply[i];
            unchecked { ++i; }
        }
    }

    /// @notice Phase set using a uint, 1 for FnF, 2 for Public
    function setPhase(uint8 _phase) 
        public 
        onlyOwner 
    {
        mintPhase = _phase;
    }


    //////////////////////////////////////
    // Type: Aux Admin // Auth: Admin //
    //////////////////////////////////////

    function devMint(uint256 _quantity) 
        public 
        onlyOwner 
    {
        if (totalSupply() + _quantity > maxSupply) revert maxTotalKeeny();
        _mint(msg.sender, _quantity);
    }

    function withdrawFunds() 
        external 
        onlyOwner 
    {
        uint256 _value = address(this).balance;
        address _to = msg.sender;
        (bool success, ) = _to.call{value: _value}("");
        require(success, "Call Failed");
    }

    ////////////////////////////////////
    // Type: KeenVerse // Auth: Admin //
    ////////////////////////////////////

    function setKeenLand(address _keenLand) public onlyOwner {
        KeenLand = _keenLand;
    }

}