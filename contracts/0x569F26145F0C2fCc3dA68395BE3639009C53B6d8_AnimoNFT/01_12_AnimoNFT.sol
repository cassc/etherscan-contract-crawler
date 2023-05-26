// contracts/AnimoNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//////////////////////////////////////////////////
//                                              //
//    `+yhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhy+`    //
//   /hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh/   //
//   hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh   //
//   hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh   //
//   hhhhhhhhhhhhhhhs+/:--:/+yhhhhhhhhhhhhhhh   //
//   hhhhhhhhhhhhs:         `shhhhhhhhhhhhhhh   //
//   hhhhhhhhhhy`         `+hhhhhhhhhhhhhhhhh   //
//   hhhhhhhhhs         `+hhhhhhhhsyhhhhhhhhh   //
//   hhhhhhhhh`       `+hhhhhhhh+` `hhhhhhhhh   //
//   hhhhhhhh/      `+hhhhhhhh+`    +hhhhhhhh   //
//   hhhhhhhh+    `+hhhhhhhh+`      +hhhhhhhh   //
//   hhhhhhhhh` `+hhhhhhhh+`       `hhhhhhhhh   //
//   hhhhhhhhhyshhhhhhhh+`        `shhhhhhhhh   //
//   hhhhhhhhhhhhhhhhh+`         :yhhhhhhhhhh   //
//   hhhhhhhhhhhhhhhs`        `:yhhhhhhhhhhhh   //
//   hhhhhhhhhhhhhhhy+/:--//+yhhhhhhhhhhhhhhh   //
//   hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh   //
//   hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh   //
//   /hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh-   //
//    `+shhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhs/`    //
//                                              //
//                 A.N.I.M.O                    //
//////////////////////////////////////////////////

contract AnimoNFT is ERC721, Ownable {
    event Received(address from, uint256 amount);
    event NewAnimo(address indexed cadet, uint256 count);

    string tokenBaseURI;
    bool public paused = true;
    bool public presale = true;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 private constant RESERVED = 268; // reserved for the team
    uint256 private constant MINT_SUPPLY = MAX_SUPPLY - RESERVED;
    uint256 public price = 0.088 ether;
    uint256 public totalSupply;
    address[] private members;

    mapping(string => bool) private isNonceUsed;
    mapping(address => uint256) private qtyByCadet;

    constructor(
        uint256 _totalCollabs,
        string memory _tokenBaseURI,
        address[] memory _members
    ) ERC721("A.N.I.M.O", "ANIMO") {
        tokenBaseURI = _tokenBaseURI;
        members = _members;

        // Collabs pre-mint
        for (uint256 i = 0; i < _totalCollabs; i++) {
            _safeMint(msg.sender, i);
        }
        totalSupply = _totalCollabs;
    }

    /* Public functions _______*/

    // allow the contract to receive ether
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function mint(
        uint256 _quantity,
        uint256 _maxQty,
        bool _freeMintEligible,
        string memory _nonce,
        bytes memory _signature
    ) public payable {
        require(!paused, "paused");
        require(presale, "presale off");
        require(totalSupply + _quantity <= MINT_SUPPLY, "soldout");
        require(
            qtyByCadet[msg.sender] + _quantity <= _maxQty,
            "max amount exceeded"
        );

        address signerAddress = _verifySign(
            msg.sender,
            _maxQty,
            _freeMintEligible,
            _nonce,
            _signature
        );
        require(signerAddress == owner(), "not authorized");
        require(!isNonceUsed[_nonce], "nonce used");

        if (!_freeMintEligible) {
            require(msg.value >= price * _quantity, "insufficient funds");
        }
        isNonceUsed[_nonce] = true;
        uint256 firstTokenId = totalSupply;
        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(msg.sender, firstTokenId + i);
        }
        totalSupply += _quantity;
        qtyByCadet[msg.sender] += _quantity;
        emit NewAnimo(msg.sender, _quantity);
    }

    function mintPublic(uint256 _quantity) public payable {
        require(!paused, "paused");
        require(!presale, "presale on");
        require(totalSupply + _quantity <= MINT_SUPPLY, "soldout");
        require(_quantity < 11, "max qty exceeded");
        require(msg.value >= price * _quantity, "insufficient funds");

        uint256 firstTokenId = totalSupply;
        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(msg.sender, firstTokenId + i);
        }
        totalSupply += _quantity;
        emit NewAnimo(msg.sender, _quantity);
    }

    function ownedBy(address _owner) external view returns (uint256[] memory) {
        uint256 counter = 0;
        uint256[] memory tokenIds = new uint256[](balanceOf(_owner));
        for (uint256 i = 0; i < totalSupply; i++) {
            if (ownerOf(i) == _owner) {
                tokenIds[counter] = i;
                counter++;
            }
        }
        return tokenIds;
    }

    function burn(uint256 tokenId) external {
        require(paused, "not paused");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "burn caller is not owner nor approved"
        );
        _burn(tokenId);
        totalSupply -= 1;
    }

    /* Internal functions _______*/
    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    function _verifySign(
        address _to,
        uint256 _maxQty,
        bool _freeMintEligible,
        string memory _nonce,
        bytes memory _signature
    ) internal pure returns (address) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(_to, _maxQty, _freeMintEligible, _nonce)
                ),
                _signature
            );
    }

    /* Admin functions _______*/
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPause(bool _isPause) external onlyOwner {
        paused = _isPause;
    }

    function setPreSale(bool _presale) external onlyOwner {
        presale = _presale;
    }

    function setTokenBaseURI(string memory _uri) external onlyOwner {
        tokenBaseURI = _uri;
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner {
        require(address(this).balance > 0, "balance is zero");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "transfer failed");
    }

    function withdrawAll() external onlyOwner {
        uint256 _totalBalance = address(this).balance;
        require(_totalBalance > 0, "balance is zero");

        uint256 _amount = _totalBalance / members.length;
        for (uint256 i = 0; i < members.length; i++) {
            (bool success, ) = members[i].call{value: _amount}("");
            require(success, "transfer failed");
        }
    }

    function mintRemaining(address _to, uint256 _qty) external onlyOwner {
        require(totalSupply + _qty <= MAX_SUPPLY, "max reached");
        uint256 firstTokenId = totalSupply;
        for (uint256 i = 0; i < _qty; i++) {
            _safeMint(_to, firstTokenId + i);
        }
        totalSupply += _qty;
    }
}