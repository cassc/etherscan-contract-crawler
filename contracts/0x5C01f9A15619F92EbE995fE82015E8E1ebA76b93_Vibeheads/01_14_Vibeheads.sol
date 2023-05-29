// SPDX-License-Identifier: MIT                                                                                                    

/* 

+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
+                                                ..........                                                     +
+                               -+##*-.         ............            ......                                  +
+         ..:----:::.....    .=#@@@@@@%+.                           ...=+##**+==.        :*:-%%=::+             +
+     .#+++=++++====---:::.  #@@@%%%##%%*.                         :+#*+-====#@@*-     :+#**+****%@#-.          +
+     :@@#*++++++===-:---:   *+=.        .      ....    .....    --.#=       .-#@%-.   #%*+=.:[email protected]@@#.         +
+      [email protected]@%%%%%#*****+=--=  -#==:..      .     ::::.......::::  :*=#= ...  ..::[email protected]@%#. =%##-:::-=++%@@@*         +
+       .#%@%####++***+*=: -+%*++*:.:====:   :+=--:::..:::--=+=  +:::-=+=:.:*++#%@%%= +%#*+++-=*##@@@@+         +
+        [email protected]@@@@@%+#@@@#*#  [email protected]@###+-..=**:-=  #+#+=---::---==*[email protected] :  -:*#=. =+###@*-#. =%##%@#[email protected]#@@@@@+         +
+        :@@@@@@#=+***#*=  [email protected]@#=--:  ..::+-  *@@#+==----==+*%@@  :=:=::..+#%=:-#@%%*  -%%#**=-=%##@@@@=         +
+         :%@@@@%#**##%-.    [email protected]##%%##+==+-.   .-%#*++==++**#+.     :=%+*%@@@@%#%%#.   :#*#**++#@@%@@@@=         +
+          :%%%%@%%*+#+      :@@@@%#%#%##.      -##*++++**#+       .*%*=+-===+=%@.    .#.#*+*#@@@@@#@@-         +
+           :@@@%####+       [email protected]@#[email protected]@-.   .::-=********=-:::    -=..+*-::=#= -*=.   %.-*%*+*%@%=.%%-         +
+          .%@@@@@@@@@:    *@@%@@@@@@@@*#@@+ -:=+**%%%%%%*+++:-     -=+*%@@@%    .=:  .* -#%%%@@@@*:##:         +
+      :%+=%@@@@%*%@%%#-  [email protected]@@@@@@@@@#+==%%*.-:=+%*#@@@@%*##=:-    .--=*#%%%#+#%@@@=   #*%%%#*#%@%%@@+.         +
+     [email protected]@@@@@@@%#%@%%%@%*@@@@@@@@@@%###%###=#=:+#*######*#*--*-.   .  .:-*+=****#@@@@@@%%%%##**#%@@@@@#=       +
+     @@@@@@@@@@@@@@%%@%@@@@@%@@@@@@@@%=:=::-+*-=***+**+*##=:=*-:.....  .:::::=*%@@@@@@@@%%%#**###*%%#%%@@      +
+                                                                                                               +
+                                                                                                               +
+                                                                                                               +
+                                      █░█ █ █▄▄ █▀▀ █░█ █▀▀ ▄▀█ █▀▄ █▀                                         +
+                                      ▀▄▀ █ █▄█ ██▄ █▀█ ██▄ █▀█ █▄▀ ▄█                                         +
+                                                                                                               +
+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +

Written by @0xmend

*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Vibeheads is ERC721Enumerable, EIP712 {
    using ECDSA for bytes32;
    using Strings for uint256;
    string private constant SIGNING_DOMAIN = "Vibeheads";
    string private constant SIGNATURE_VERSION = "1";
    string public provenance;
    string public baseTokenURI;
    string public contractMetadata;
    uint256 public maxSupply = 5555;
    uint256 public cost = 0.08 ether;
    uint256 public maxMintAmount = 2;
    bool public preSalePaused = true;
    bool public publicSalePaused = true;
    address public owner;
    address public constant teamAddress = 0x6114183FC6E47a4B412a2b5231B7Ed472DAcfF19;
    mapping(address => uint256) public presaleRedeemed;

    constructor(string memory _contractMetadata, string memory _initBaseURI) 
        ERC721("Vibeheads", "VIBE")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
            owner = msg.sender;
            contractMetadata = _contractMetadata;
            baseTokenURI = _initBaseURI;
        }

    struct VibePass {
        address recipient;
        uint256 maxAmount;
        bytes signature;
    }

    function _mintVibehead(address to, uint256 amount, uint256 supply) internal {
        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(to, supply + i);
        }
    }

    function mint(uint256 _mintAmount) external payable returns (uint256) {
        uint256 mintCost = cost;
        if (msg.sender == owner) {
            mintCost = 0;
        } else {
            require(!publicSalePaused, "Public sale is paused");
            require(_mintAmount <= maxMintAmount, "Mint amount greater than max mint amount");
        }
        require(_mintAmount > 0, "Mint amount should be greater than 0");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "Sold out!");
        require(msg.value >= mintCost * _mintAmount, "Insufficient funds");
        _mintVibehead(msg.sender, _mintAmount, supply);
        return supply + _mintAmount;
    }

    function redeem(VibePass calldata _pass, uint256 _redeemAmount) external payable returns (uint256) {
        uint256 mintCost = cost;
        if (msg.sender == owner) {
            mintCost = 0;
        } else {
            require(!preSalePaused, "Presale is paused");
        }
        address redeemer = msg.sender;
        address signer = _verify(_pass);
        require(signer != address(0), "Unable to recover signer from signature");
        require(signer == owner, "Invalid Vibe Pass");
        require(redeemer == _pass.recipient, "This Vibe Pass does not belong to you");
        require(_redeemAmount > 0, "Redeem amount should be greater than 0");
        require(_redeemAmount <= _pass.maxAmount, "Redeem amount greater than allowed limit");
        require(_redeemAmount <= _pass.maxAmount - presaleRedeemed[redeemer], "Vibe Pass limit reached");
        uint256 supply = totalSupply();
        require(supply + _redeemAmount <= maxSupply, "Max Vibeheads limit crossed");
        require(msg.value >= mintCost * _redeemAmount, "Insufficient funds");
        presaleRedeemed[redeemer] += _redeemAmount;
        _mintVibehead(redeemer, _redeemAmount, supply);
        return supply + _redeemAmount;
    }

    function setBaseTokenUri(string memory _base) external {
        require(msg.sender == owner, "You can't change baseTokenURI");
        baseTokenURI = _base;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setMintAmount(uint256 _newMaxMintAmount) external {
        require(msg.sender == owner, "You can't change mint amount");
        maxMintAmount = _newMaxMintAmount;
    }

    function setNewOwner(address _newOwner) external {
        require(msg.sender == owner, "You can't change owner");
        owner = _newOwner;
    }

    function setProvenance(string memory _newProvenance) external {
        require(msg.sender == owner, "You can't change provenance");
        provenance = _newProvenance;
    }

    function pausePresale(bool _state) external {
        require(msg.sender == owner, "You can't change presale state");
        preSalePaused = _state;
    }

    function pausePublicsale(bool _state) external {
        require(msg.sender == owner, "You can't change public sale state");
        publicSalePaused = _state;
    }

    function withdraw() external {
        require(msg.sender == owner, "You can't withdraw");
        payable(teamAddress).transfer(address(this).balance);
    }

    function contractURI() public view returns (string memory) {
        return contractMetadata;
    }

    function _hash(VibePass calldata pass) internal view returns (bytes32) {
        return  _hashTypedDataV4(keccak256(abi.encode(keccak256("VibePass(address recipient,uint256 maxAmount)"), pass.recipient, pass.maxAmount)));
    }

    function _verify(VibePass calldata pass) internal view returns (address) {
        bytes32 digest = _hash(pass);
        return digest.toEthSignedMessageHash().recover(pass.signature);
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly { id := chainid() }
        return id;
    }
}