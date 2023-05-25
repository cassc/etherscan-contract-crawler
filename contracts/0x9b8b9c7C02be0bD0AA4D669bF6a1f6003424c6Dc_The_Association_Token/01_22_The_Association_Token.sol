pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: GPL-3.0-or-later

/*

kkkkkkkOK0kkOXN0kkOXKkkkkkk0WMMM0kXMMMW0kkkkOXMMMNOdoodkXMWWKxoood0WMMMNOkkkk0NMMMW0doookXMWKkkkKMMN0kkkkONXkkkkkkkOK0kkOXMW0xoooxKWMXkkkOXMKkkONXkxkk
........l:...x0;..,Oo......:XMWX:,0MWMK;.....xMM0:.    .,ONx'.    .lXNd,......;kWXl.    .,kNl...oWM0,....'ko........c:...kXl.    .'xNd....dWo..'OKdl;.
;.   .':o,  .x0'  .kl   .,,oN0c'.'kNMMk.     cWNc   ',   :x'  .:.  .xd.  .,'.  '0d   ';.  ,0l   lWMd.     lx;.    ':o,  .xd.  .:.  'Oo    ;Xo  .kW0ocd
Wx.  '0WK,  .x0'  .kl   cNWWK;   .,kMWo   .  ,KX;   dO;..cl.  ;Kd..'dc   lKk;  .xc   oK,  .kl   lWWc  ..  :XMx.  ,0WK,  .xl   lX;  .xo    .xo  .kk..lx
Mk.  '0MK;   ok.  .kl   :KKXO'  .dllNX;  ',  .kX;   c00KXNx.  .x0KXNXc   oXO;  .dc   oNOxxkKc   lWK,  ,,  '0Mk.  ,KMK,  .xl   lX:  .dl     cc  .kO:;;;
Mk.  '0MK,   ..   .kl    ..l0:   ,;.oO'  :l   dWo    ..,lK0,    .':kXc   oXO;  .d:   oMMMMMWc   lWO.  cc  .xMk.  ,KMK,  .xl   lX:  .dl   . .,  .kKo;,,
Mk.  '0MK,   ..   .kl   .''lX0,  .;:xd.  ox.  cNNxc,'.   :X0o;,.   .xc   oXO;  .d:   oMMMMMNc   lWd   dd   lWk.  ,KMK,  .xl   lX:  .dl  .;.    .kMWdc:
Mk.  '0MK,  .oO'  .kl   cXNWWMXo. lNWl   .'   ,0NXXXXd.  'ONXXXK;   c:   lXO;  .dc   oNkooxKc   lNc   ..   ;Xk.  ,KMK,  .xl   lX:  .dl  .o,    .kMWOxo
Mk.  '0MK,  .x0'  .kl   cXNWMMMWKl;kX;        .xo..'kk.  ,o;..lKc   lc   oKk;  .xc   o0,  .kl   l0,        .Ok.  ,KMK,  .xl   lK;  .xo  .kl    .OWNNXc
Mk.  '0MK;  .x0'  .kl   ..'lNMMMMWdxO.  .dk,   ol   .'   :k'  .,.  .xo   ':,.  'Od   .,.  ,0l   lk.  'xx'   dk.  ,KMK,  .xx.  .,.  'Oo  .kO.   .kKdol.
MO,..:KMXc..'kK:..;Od......cXMMMMM0kx,..cXWo...o0o'.....:0Wk;.....'dNKc.      'xNXo'.....;ONo...od'..lNNl...dO,..cXMXc..,kNd'.....,kWd..,ONl...;0WWWNl
MNK00KWMWX00KNWK00KWN000000XWMMMMMWWNKK0XWMN000XWWXOxkkKWMMMN0kxkOXWMMN0dllooxKWWMMXOkkk0NMWX000XX000XMMX000XNK00XWMWX00KNMMXOkkk0NMMNK0KNWX000KNMMMWX

*/

/// @author: galaxis.xyz - The platform for decentralized communities.

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";

import "./ssp/recovery.sol";
import "./ssp/IRNG.sol";

import "./ssp/token_interface.sol";

contract token_configuration {
    string _tokenPreRevealURI;
    uint256 immutable _maxSupply;
    bool _locked;

    constructor(
        string memory tpi,
        uint256 ms,
        bool lock
    ) {
        _tokenPreRevealURI = tpi;
        _maxSupply = ms;
        _locked = lock;
    }
}

contract The_Association_Token is
    ERC721Enumerable,
    token_configuration,
    token_interface,
    Ownable,
    recovery,
    ReentrancyGuard
{
    using Strings for uint256;

    uint256 public immutable projectID;
    IRNG public immutable _iRnd;
    mapping(address => bool) public override permitted;

    bytes32 _reqID;
    bytes32 _secondReq;
    bool _randomReceived;
    bool _secondReceived;
    uint256 _randomCL;
    uint256 _randomCL2;
    string _tokenRevealedBaseURI; // base of URI points to a folder in EtherCards format (see readme)
    uint256 _ts1; // total supply when baseURI set
    uint256 _ts2; // total supply after second reveal (no more minting after this please)
    uint256 public reserved;
    uint256 public constantReserved;
    address projectFactory;

    uint256 public index1;
    uint256 public index2;

    event Allowed(address, bool);
    event Locked(bool);
    event RandomProcessed(
        uint256 stage,
        uint256 randUsed_,
        uint256 _start,
        uint256 _stop,
        uint256 _supply
    );

    modifier onlyAllowed() {
        require(
            permitted[msg.sender] || (msg.sender == owner()),
            "Unauthorised minter"
        );
        _;
    }

    constructor(
        uint256 _projectID,
        IRNG _rng,
        string memory _name,
        string memory _symbol,
        string memory __tokenPreRevealURI,
        uint256 _maxSupply,
        bool __locked,
        address _projectFactory,
        uint256 _reserved
    )
        ERC721(_name, _symbol)
        token_configuration(__tokenPreRevealURI, _maxSupply, __locked)
    {
        projectID = _projectID;
        _iRnd = _rng;
        projectFactory = _projectFactory;
        reserved = _reserved; //1480
        constantReserved = 480;
    }

    function setAllowed(address _addr, bool _state)
        external
        override
        onlyAllowed
    {
        permitted[_addr] = _state;
        emit Allowed(_addr, _state);
    }

    function mintCards(uint256 numberOfCards, address recipient)
        external
        override
        onlyAllowed
    {
        _mintCards(numberOfCards, recipient);
    }

    function batchMint(
        address[] memory recipients,
        uint256[] memory numberOfCards
    ) external onlyAllowed {
        require(recipients.length == numberOfCards.length, "!length");
        uint256 totalLength = recipients.length;
        for (uint256 i = 0; i < totalLength; i++) {
            _mintCards(numberOfCards[i], recipients[i]);
        }
    }

    function _mintCards(uint256 numberOfCards, address recipient) internal {
        uint256 supply = totalSupply();
        require(
            supply + numberOfCards <= _maxSupply - reserved,
            "This would exceed the number of cards available"
        );
        for (uint256 j = 0; j < numberOfCards; j++) {
            _mint(recipient, supply + j + 1);
        }
    }

    function reserveMintCards(uint256 numberOfCards, address recipient)
        external
        onlyAllowed
    {
        uint256 supply = totalSupply();
        require(
            numberOfCards <= reserved,
            "This would exceed the number of cards available"
        );
        reserved = reserved - numberOfCards;
        for (uint256 j = 0; j < numberOfCards; j++) {
            _mint(recipient, supply + j + 1);
        }
    }

    // RANDOMISATION --cut-here-8x------------------------------

    function setRevealedBaseURI(string calldata revealedBaseURI)
        external
        onlyAllowed
    {
        _tokenRevealedBaseURI = revealedBaseURI;
        if (!_randomReceived) _reqID = _iRnd.requestRandomNumberWithCallback();
    }

    uint256 public _start1;
    uint256 _stop1;
    uint256 _start2;

    function resetReveal() external onlyOwner {
        _randomReceived = false;
    }

    function process(uint256 random, bytes32 reqID) external {
        require(msg.sender == address(_iRnd), "Unauthorised RNG");
        if (_reqID == reqID) {
            require(!(_randomReceived), "Random No. already received");
            _randomCL = random / 2; // set msb to zero
            _start1 = _randomCL % (_maxSupply + 1);
            _randomReceived = true;
            _ts1 = totalSupply();
            _stop1 = uri(_ts1);
            emit RandomProcessed(1, _randomCL, _start1, _stop1, _ts1);
        } else revert("Incorrect request ID sent");
    }

    function setPreRevealURI(string memory _pre) external onlyAllowed {
        _tokenPreRevealURI = _pre;
    }

    function uri(uint256 n) public view returns (uint256) {
        if (n <= _ts1) {
            if ((n + _start1) <= _maxSupply) {
                return n + _start1;
            }
            return n + _start1 - _maxSupply;
        } else {
            uint256 range = _maxSupply - _ts1;
            uint256 pos_in_range = 1 + ((n - _ts1 + _randomCL2) % range);

            if ((_stop1 + pos_in_range) <= _maxSupply) {
                //console.log("A");
                return _stop1 + pos_in_range;
            }
            if ((_stop1 + pos_in_range) - _maxSupply <= _start1) {
                //console.log("B");
                return (_stop1 + pos_in_range) - _maxSupply;
            }
            //console.log("C");
            uint256 from_left = (_stop1 + pos_in_range) - _maxSupply + 1;
            return (from_left - _start1) + _stop1;
        }
    }

    function availableToMint() public view override returns (uint256) {
        return _maxSupply - totalSupply() - reserved;
    }

    function setStart1(
        uint256 __start1,
        bool _status,
        string memory _stingSome
    ) external onlyOwner {
        _start1 = __start1;
        _randomReceived = _status;
        _tokenRevealedBaseURI = _stingSome;
        _ts1 = totalSupply();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        string memory revealedBaseURI = _tokenRevealedBaseURI;

        if (!_randomReceived) return _tokenPreRevealURI;
        uint256 newTokenId = uri(tokenId);

        string memory folder = (newTokenId % 100).toString();
        string memory file = newTokenId.toString();
        string memory slash = "/";
        return string(abi.encodePacked(revealedBaseURI, folder, slash, file));
        //
    }

    function tellEverything() external view override returns (TKS memory) {
        return
            TKS(
                totalSupply(),
                _ts1,
                _ts2,
                _randomReceived,
                _secondReceived,
                _randomCL,
                _randomCL2,
                _locked
            );
    }

    function setTransferLock(bool locked) external onlyAllowed {
        _locked = locked;
        emit Locked(locked);
    }

    // Add lock until sellout or unlocked
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal override {
        if (from == address(0)) {
            super._beforeTokenTransfer(from, to, _tokenId);
            return;
        }
        require(!_locked, "Transfers are not enabled");
        // this is the fix.
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    function tokenPreRevealURI()
        external
        view
        override
        returns (string memory)
    {
        return _tokenPreRevealURI;
    }
}