// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* -----------------------+****+--------------------------+********+----------------------+##############=-----------------+###############=-----------
----=++=-----=++==---------==---------------=-------------+******=----------------------=#######**######*-----------------*######**#######=-----------
--=******+-=******+------------------------+*+-------------+****=-------------=----------*#####++=*#####=-----------------=*###*+-*=+*##*+------------
--=****************----------------------=*****-------------+*+------------+*###*=--------=++=-=#+--===--------------------------=#=------------------
---***************=---------------------=*******=------------=------------=#######-------------+##=-------------=**+-------------*#*------------------
----+************=---------------------=*********=------------------------=######*-------------====-----------=*#####+=---------====------------------
-----+**********=----------------------***********----------------------=+**#####***+=-----------------------*#########+------------------------------
-------+******+------------------------=*********=---------------------*##############+--------------------=############*=--------------------=+***+=-
--------=+**+---------------------------=******+----------------------=#######**######*-------------------=##############*--------------------+*******
=-------------------------=*=------------=****=------------===---------+####*=*=+*###*=-------------------+###############+-------------------+*******
*------------------------=***=-------------**=-+*##*+=-=+=*####*---------==--=#*---=----------------------=######+++######=--------------------+******
*-----------------------+*****=-----=++**+++*#@%%%%#%@%@#@######+------------*##=--------------=-----------=++++=-#=-=+++=----------------------+*****
=----------------------+*******+=*%@%############*****%@=#@#####=----------------------------=*##+=--------------+#*-----------------------------=+***
----------------------+********%@%#%******************@#=:@%###****+=----------------------=*######+=------------***=------------------------------=+*
----------------------+******#@@#*%******************#@%#=#@@########=-------------------=*##########+-----------------------------------------------=
-----------------------+****#@@**##******************%%+-::@%@%######=------------------=#############*-----------------------------------------------
---------=--------------+**#@@***#*******************@#+--:%%#@%*##*=-----=++**#**+-----*##############+-----------------------==+==----==++=---------
--------+**=-------------+*@@****%#*****************#@##****@*#@#---=+*#%%%%######@@*---#######**#######----------------------+******=-+******=-------
-------+****=-------------*@%****%#*****************@#[email protected]%##@##%%#************#%@+--+#####++=+*####+----------------------****************=-------
------*******=------------#@*****##*##*************#@#**+==+%@[email protected]#**#####********%%@+----===--**--===------------------------=***************--------
----=*********+-------====%@***###%*##************#@%*#*[email protected]#*#%%##************##@#---------=##=-----------------------------=*************=--------
----+**********=-=+#%@@%%%@@@%%##*%**********#%%#[email protected]*++=----:@@****************#%%@%+---------=++=------------------------------=**********+----------
-----*********=+#@@%###########%@@@#*****#%%#*++=-#@%#**+++**%@**************#%@@@###+--------------------------------------------=*******=-----------
------+*******@@%#*************###%%%@%%@**+++++*#@#*##*++=-:[email protected]#**********#%@@@%######=----------------------+++++----=+*++=--------=+*+=-------------
-------+****%@%*********************###%%@@###%#*#@#**++===+*%@#*******#%@@%*@**######+---------------------+******+=*******=-------------------------
--------+*[email protected]@***************************###%%%@@%%%@@@@@@%%%#****##%@@@*+*%%#%*-+*###*=---------------------+***************=------------------------+
---------=%@****************##***************#####%%%%%%@@@@@@@@@@#+-.   :-+%@@#+=--------------------------=**************+------------------------**
[email protected]#*****************##%%%@@%%%%%##########%%@@@%##*+=-: .:-++*%@@@@%%%@@@#+-------------------------=************+-----------------------=***
---------#@**************@@%+*****++==*#@@@@@#=--:::.::-=+++*%%*=:..:@@%%%%%%%%%%%@@@*=------------------------+*********=-----------------------=****
---------%@*************#@%**.           :+%@@@#+-=#%@@@@%%%%%@@@%=++%@@%%%%%%%%%%%%@@%#=------------------------+*****+-------------------------=****
---------*@#*************@@-=#+             .=%@@@@%%%%%%%%%%%%%%%@@  [email protected]@@%%%%%%%%%%@-=%#==+**+=---=+***+=--------++=----------------------------=***
[email protected]@*************#@#--=#+.             %@%%%%%%%%%%%%%%%%%%@: ..=#%%@@@@%%@@@#=++%@%#*****=+*******------------------------=**-------------=**
----=#####%@%*************@@+----*+-           [email protected]@%%%%%%%%%%%%%%%%%@+-+#+=---=+****+-------#@%************+-----------------------=****=------------=*
----+#######@@*************@@=------+=-.        [email protected]@%%%%%%%%%%%%%%%%@*-----------------------=%@#**********=----------------------=******=------------=
----=*#####[email protected]@#************@@=--------:         -%@%%%%%%%%%%%%%%@%--------------------------*@#********=----------------------=********=------------
-+*###########%@@#***********@@+------.            =#@@%%%%%%%%@@%*[email protected]%*****+-----------------------=**********=-----------
+#######*########%@%**********%@*----.               .-+##%%%@#*=-------------------------------=%@#*+=-------------------------*********+------------
=######+++######=-+#@@%#******@*-#+-:                       [email protected]%=--------------=-------------*******+-------------
-=+**+==#==++++=-----=*#@@%##%@:  :*-                     .*[email protected]#-------------+*+-------------+****=--------------
-------*#*--------------+%###@%    *:                    .*[email protected]+-----------+***+-------------+**=-----------=*##
------=+++=-------------*%##%@+    #.                    #------------------------------------------#@=---------*******-------------+------------=####
----------------------+##%@%%@-    *                    [email protected]*-------=*********=------------------------=####
--------------------+####%**#@:    +                   :*--------------------------------------------#@-------***********=---------------------=++*###
-------------------*#####%##%@:    +                   #[email protected]+------=*********=---==----------------*#######
------------------*######@**#@:    +                   #[email protected]*----#####%@%@@@@@@@@@@@%####+--------=#######*
-----------------=###%@@@@**#@:    =:                  #----+*---------------------------------#+-#[email protected]*[email protected]   #=    :@*##*+==-:.#%---------+#####+*
-----------------=%@@@@@@@**#@:    :=                :*----=%:#+------------------------------=#[email protected]*[email protected]=   %=    #+    .:-*@@%%%###*=----====-=#
------+**+-------*@@@@@@@@**#@:     *        *.     .*-----#-  =#[email protected][email protected]+   @-   [email protected]      -%:-*#+-..#%---------*#
----+*#####[email protected]@@@@@@@@@%#@-     *         *-    [email protected]%=   -##=--------+#+==**-----------------%@[email protected]+   @:   *#      =%.    .=##@#=--------==
--=*########*[email protected]@@@@@@@@@@@@+     #-         =*.  #[email protected]@@%+:. .+#*------**[email protected]#[email protected]+  [email protected]   @-     *%.      :*%%*#%*=-------
-+############[email protected]@@@@@@@@@@@@@@#=. +=      .-. ##+.*+**#%@@%%%%%%#+. :=**[email protected]%*+----%*  :@   [email protected]     *#      -#*. -#*::+##+----
=##############*-=#@@@@@@@@@@@@@@@@@#*:       -*%=*#@%%%%%%%%%%%%%%%%-    :[email protected]%*=-----%*  [email protected]   %+    #*     =%+.     :%*..%#----
*###############[email protected]@@@@@@@@@@@@@@@@@@@#+-.   [email protected]***+#%%%%%%%%%%%%%%%@@#+-. .-=#@#+=-------------#@%*=---=++%*  -%  :@.  .%+    =%+          -%@#-----
+######+++######[email protected]@@@@@@@@@@@@@@@@@@@@@@@@%**@=+=++=%%%%%%%@%#*##*@@@@@@@@@%#=--------------*@@#*==+#%@@@@*  =#  **  .%=  .+%=        .--   -%#=---
-=+++=-=*-=++++-----%@@@@@@@@@@@@@@@@@@@@@@@@@@@@*+=++*%%%%@@@%#+-::+#@@@@@%*=--------------+#@@@#%%@@@@@@@@@#  +# [email protected]: [email protected] .*#-  .:-=*#%@@@=     -%#=-
-------*#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#**@@@@@@@@@@@@%#**++=--------------=+#%@@@@@@@@@@@@@@@@@@#  ** =% [email protected]:.*#-   [email protected]@@@@@@@@%        [email protected]+
------=***---------*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%##********##%@@@@@@@@@@@@@@@@@@@@@@@@#  #+ %==%=#*:     %@@@@@@@@@-       =%#+
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%+##@@@%@%%*@@@@@@@@@@@@@@@@@@@@@@@@%==%#[email protected]*@@+.      [email protected]@@@@@@@@#      [email protected]*+*#
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@%.%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=       :@@@@@@@@@@:    [email protected]*=*###
------------------%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@.#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:     %@%#*+=-:.   .*%*-=*####
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@::@@@@@@.*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.   .          :*%+---*#####
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:[email protected]@@@@@:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+.          :#%+-----######
------------------*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@:[email protected]@%**#@@@#++#@@@@@@@@@@@@@@@@@@@@@@@@@@@@+       -#@*-------=*###*
-------------------%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@[email protected]@=...:#*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@*%=   -%@###*=--------=--
--------------------#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@[email protected]@+.....:.....%@@@@@@@@@@@@@@@@@@@@@@@@@#-+%%+%@#######+----------
--------------------%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@++%@@@@@*[email protected]@%=.........:@@@@@@@@@@@@@@@@@@@@@@@%*=-+###%##########+---------
----=+**+=---=+**[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--%@@@@@#[email protected]@@@#:.......#@@@@@@@@@@@@@@@@@@@@%*=----*###############---------
---+******+=*******#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*-...:#@@@@@@@@@@@@@@@@@#*+--------*######=+*######---------
---=***************%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+%@@@@@@@@@@@%##*+=-------------++*++-=*-=++++=---------
----+**************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-------=+=------------------*#=---------------
-----+***********[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-----=+###*=---------------+***---------------
------=*********[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=---+#######*=--------------------------------
--------=*****[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+-=###########*=-----------------------=++=---
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+=#############*=--------------------=******=-
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+###############*--------------------=********

*/

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

contract CLU is ERC721AUpgradeable, PausableUpgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {
    uint256 public maxSupply;
    uint256 public maxMint;
    uint256 public preSalePrice;
    uint256 public publicSalePrice;
    bytes32 public root;
    bool public isSaleOn;
    bool public revealStatus;
    uint256 public publicSaleStartTime;
    uint256 public preSaleStartTime;
    address public teamWallet;

    string private realBaseURI;
    string private virtualURI;

    mapping(address => uint256) public qtyMintedPerUser;

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    // - `initializer` for OpenZeppelin's `OwnableUpgradeable`.
    function initialize(
        bytes32 _root, uint256 _maxMint, uint256 _maxSupply,
        address _teamWallet, string memory _realBaseURI, string memory _virtualURI, bool _revealStatus,
        uint256 _preSaleStartTime, uint256 _publicSaleStartTime
) public initializerERC721A initializer {
        root = _root;
        maxMint = _maxMint;
        maxSupply = _maxSupply;
        preSalePrice  = 0.01 ether;
        publicSalePrice = 0.015 ether;
        realBaseURI = _realBaseURI;
        virtualURI = _virtualURI;
        publicSaleStartTime = _publicSaleStartTime;
        preSaleStartTime = _preSaleStartTime;
        revealStatus = _revealStatus;
        isSaleOn = true;
        __ERC721A_init("CRAZY LITTLE UNICORNS", "CLU");
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        teamWallet = _teamWallet;

    }


    function preSale(uint256 quantity, bytes32[] memory proof) external payable {
        require(block.timestamp > preSaleStartTime && block.timestamp < publicSaleStartTime, "PreSale not started");
        require(totalSupply() + quantity <= maxSupply, "Exhausted");
        require(isSaleOn, "PreSale is NOT on");
        require(msg.value >= (quantity * preSalePrice), "Insufficient price");
        require(isWhiteListed(proof, keccak256(abi.encodePacked(msg.sender))), "Not whitelisted");
        require(qtyMintedPerUser[msg.sender] + quantity <= maxMint, "Max wallet exceeded");
        qtyMintedPerUser[msg.sender] += quantity;
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);

    }

    function publicSale(uint256 quantity) external payable {
        require(block.timestamp >= publicSaleStartTime, "Public Sale not started");
        require(totalSupply() + quantity <= maxSupply, "Exhausted");
        require(isSaleOn, "PublicSale is NOT on");
        require(msg.value >= quantity * publicSalePrice, "Insufficient price");
        require(qtyMintedPerUser[msg.sender] + quantity <= maxMint, "Max wallet exceeded");
        qtyMintedPerUser[msg.sender] += quantity;
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);

    }

    function adminMint(address wallet, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        _mint(wallet, quantity);
    }

    function setRoot(bytes32 __root) external onlyOwner {
        root = __root;
    }

    function setSaleStartTime(uint256 _preSaleStartTime, uint256 _publicSaleStartTime) external onlyOwner {
        preSaleStartTime = _preSaleStartTime;
        publicSaleStartTime = _publicSaleStartTime;
    }

    function setPrice(uint256 _newPresaleprice, uint256 _newPublicsaleprice) external onlyOwner {
        preSalePrice = _newPresaleprice;
        publicSalePrice = _newPublicsaleprice;
    }

    function setUri(string memory _newUri, string memory _virtualUri) external onlyOwner {
        realBaseURI = _newUri;
        virtualURI = _virtualUri;
    }

    function setRevealStatus(bool _status) public onlyOwner {
        revealStatus = _status;
    }

    function startSale() external onlyOwner {
        require(!isSaleOn, "Can't start");
        isSaleOn = true;
    }

    function stopSale() external onlyOwner {
        require(isSaleOn, "Presale is not on");
        isSaleOn = false;
    }

    function withdraw(address payable  _wallet) external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "No funds");
        _wallet.transfer(bal);
    }

    // Validate address if whitelisted
    function isWhiteListed(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProofUpgradeable.verify(proof, root, leaf);
    }

    function _baseURI() internal view override returns (string memory) {
        if (revealStatus) {
            return realBaseURI;
        }
        else {
            return virtualURI;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        if (revealStatus) {
            return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
        }
        else {
            return string(abi.encodePacked(_baseURI(), "placeholder.json"));
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


}