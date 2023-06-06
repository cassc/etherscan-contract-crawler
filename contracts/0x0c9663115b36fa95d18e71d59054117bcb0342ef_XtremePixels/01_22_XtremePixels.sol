// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "./ERC721R.sol";

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=-----------------------------------------*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=------------#@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@%%%%%%%%%%%%%@@@@@@@@@@%%%%                                          =%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.            #@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@%.          [email protected]@@@@@@@@@#                                                [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.            #@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@%           -++++++++++=       ...............   .................      .+#@@@@@%++++++++++++++++++++++++++++++++++    ......   #@@@@@%+++++++++++++++*%@@@@
//@@@@%                             :======---==---=: :=----------------        [email protected]@@@@#                                     :------   #@@@@@*                %@@@@
//@@@@%   :::::                  :::-----------------:-------------------::.    .::::::                                     :------   ::::::.                %@@@@
//@@@@%   :====.                 -==--------------------------------------=:                                                :------                          %@@@@
//@@@@%   :=----:      :-----------------------------------------------------             ----------   :----     -----     --------             ---------:   %@@@@
//@@@@%   :=-----.    .-=-------------------------------------:::::----------:............----------   -----:. ..-----     --------.............---------:   %@@@@
//@@@@%   :=-----=.  .=---------------------------------------.    :--------------------------------   :-----: :------     ------------------------------:   %@@@@
//@@@@%    .-----=.  .=------------------=-   -=---=:    :----.       :=----------------------------   :-----: :-------.   ------------------------------:   %@@@@
//@@@@%     -----=:  .=-------------------:   :-----.    .=---.       .-----------------------::::-:   :-----: :-------.  .-------------------------::::::   %@@@@
//@@@@%     -=-------------=======: :=---                .=---.         :-------------------=.         :---------------. --------------------------          %@@@@
//@@@@%+-   .:=-----------:........ :=---                .=---.        :-----:..-----:.......          ----------------. ----------...-----........          %@@@@
//@@@@@@+    .=----------=:         :=---                .=---.       .=-----   :----                  :---------------. ----------   :----                 .%@@@@
//@@@@@@+    .=----------=:         :=---   -#########:  .=---.      --------   :----.      ----:       .--------------. ----------   :----      .----.  :##%%@@@@
//@@@@@@*:   .:----------:.   :::   :=---   [email protected]@@@@@@@@:  .=---.   ...-------:   :----. .....----:        --------------:.----------   :----  ....:----.  :@@@@@@@@
//@@@@@@@@:    -=------=-    [email protected]@%.  :=---   [email protected]@@@@@@@@:  .=---.  .=-------=.    :----  ---------:        --------------------------   :---- .---------.  :@@@@@@@@
//@@@@@@@@:    -=------:.    .%@%.  :=---   [email protected]@@@@@@@@:  .=----:::--------.    :-----::---------:   +-   --------------------------:::-----::---------.  :@@@@@@@@
//@@@@@@@@-    :------=.     :%@%.  :=---   [email protected]@@@@@@@@:  .=--------------:    .-----------------:  [email protected]+   ---------------------------------------------.  :@@@@@@@@
//@@@@@@@@%#    .-----=.    *%@@%.  :=---   [email protected]@@@@@@@@:  .=-------------.    ------------------    .%+   --------------------------------------------    :@@@@@@@@
//@@@@@@@@*=   .:-----=.    #@@@%.  :=---   [email protected]@@@@@@@@:  .=----------:::     ---------------:::    .%+   -------------------::--------------------::.    :@@@@@@@@
//@@@@@@@@:    -=-----=.    #@@@%.  :=---   [email protected]@@@@@@@@:  .=----------        --------------:       [email protected]+   -------------------. -------------------:       :@@@@@@@@
//@@@@@@@@:    -=-------:   .::+%.  :=---   [email protected]@@@@@@@@:  .=----------        --------.              :.   -------- .---------.  .-----------.              :::%@@@@
//@@@@@@@@:    --------=-      [email protected]  :=---   [email protected]@@@@@@@@:  .=----------        :-------                    -------- .---------.  .-----------                  %@@@@
//@@@@@@@@:  .=----------      [email protected]  :=---   [email protected]@@@@@@@@:  .=---------------      :----.                   -------- .=-------=.  .----: :----                  %@@@@
//@@@@@@#=.  .=----------:::   [email protected]  :=---   [email protected]@@@@@@@@:  .=---------------::::. :----.         .:.:.     --------  .-------.   .----. :----          .....   %@@@@
//@@@@@@+    .=----------===   [email protected]  :=---   [email protected]@@@@@@@@:  .=------------------=: :----.         -----     --------   :-----:    .----: -----          ----:   %@@@@
//@@@@@@+    .=----=--------   [email protected]  :=---   [email protected]@@@@@@@@:  .=---. ---------------------          -----     --------   :-----:    .-----------          ----:   %@@@@
//@@@@@@+   .:=----:--------   [email protected]  :=---   [email protected]@@@@@@@@:  .=---. :::::----------------.        .-----     :-------   :----::    .-----------.        .----:   %@@@@
//@@@@@@+   -----=. -=------   [email protected]  :=---   [email protected]@@@@@@@@:  .=---.      ------------------      :------      :------   :----      .------------:      :-----:   %@@@@
//@@@@@@+   -----=. .:=-----   [email protected]  :=---   [email protected]@@@@@@@@:  .=---.      .....-------------::::::-------      :----:.   .....      .-------------::::::------:   %@@@@
//@@@@@@+   -----=.  .------   [email protected]  :=---   [email protected]@@@@@@@@:  .=---.           --------------------------      :----.               .-------------------------:   %@@@@
//@@@@@@+   -----=.    :====   [email protected]  :====.  [email protected]@@@@@@@@:  .=---.                   ------------------      :=---.                       .-----------------:   %@@@@
//@@@@@@+   -----=.    .::::   [email protected]  .::::   [email protected]@@@@@@@@:  .=---.  .----.           ::-------------:::      .::::   .---------.           :-------------:::.   %@@@@
//@@@@@@+   -=---=.            [email protected]          [email protected]@@@@@@@@:  .=--=.  :@@@@+            .=-----------:                 [email protected]@@@@@@@@-            :------------.      %@@@@
//@@@@@@+   ......             [email protected]          [email protected]@@@@@@@@:   ....   :@@@@#*******=     ............                  [email protected]@@@@@@@@#*******-     ............       %@@@@
//@@@@@@+             [email protected]:[email protected]@@@@@@@@:          :@@@@@@@@@@@@#.                    [email protected]@@@@@@@@@@@@@@@@+.                    ..:%@@@@
//@@@@@@+            :%%%%%%%%%%@%%%%%%%%%%%%@@@@@@@@@:          :@@@@@@@@@@@@%%-                   %%%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@%%.                  :%%%%@@@@
//@@@@@@#============*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+===-------+%%%%@@@@@@@@@@*==================+%@@@@@@@%%%%%%%%%%%%%@@@@@@@@@@@@@+===---------------+%%@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*........   :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%:           *@@@@@@@@@@@@@@@@#................ #@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#***********-           .***%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.           *@@@@@@@@@@@@@#**=                 #@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-                           *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.           *@@@@@@@@@@@@@:                    #@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%==========.               .....       :===============%#=================    .....   *@@@@@@@@@#===.      ...........   #@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#                          -----.                      %*                    .----:   *@@@@@@@@@*          :---------:   #@@@@@@
//@@@@@@@@@@@%::::::::::::::::::::.              :::::  :::::-----::::                   ..                    .----:   *@@@@@@@%:.       :::----------:   #@@@@@@
//@@@@@@@@%###                                   -----  -------------:                                         .----:   *@@@@@@%#        .-------------:   #@@@@@@
//@@@@@@@@+                           .--------------------------------.      .------.        :---------:      .----:   *@@@@@@-      :----------------:   #@@@@@@
//@@@@%***-       ...............     :--------------------------------:.    .:------:........----------:      .----:   *@@@@@@:     .:----------::::::.   #@@@@@@
//@@@@%.         .---------------     :----------------------------------.   ---------------------------:      .----:   *@@@@@@:    .-----------:          #@@@@@@
//@@@@%.      .:::---------------:::. :----------------------.....:------.   ---------------------------:      .----:   *@@@@@@:   .:--------....          #@@@@@@
//@@@@%.      ----------------------: :----------------------     :------.   ---------------------------:      .----:   *@@@@@@:   ----------              #@@@@@@
//@@@@%.  .-::----------------------:           .-----.           :-------::---------------------:             .----:   *@@@@@@:   ------:          +######%@@@@@@
//@@@@%.  .-------------------------:            -----            :------------------------------:             .----:   *@@@@@@:   ------:          #@@@@@@@@@@@@@
//@@@@%.  .-------------.    .------:            -----              -------------- .-----                      .----:   *@@@@@@:   ------:          #@@@@@@@@@@@@@
//@@@@%.  .-------:-----.    .------:   :----.   -----   .----:     --------------  -----       .....   .---   .----:   *@@@@@@:   ------:.         =++*@@@@@@@@@@
//@@@@%.  .------. :----.     ------:   #@@@@-   -----   [email protected]@@@#     --------------  -----       -----   [email protected]@@.  .----:   *@@@@@@:   --------.           :@@@@@@@@@@
//@@@@%.   ......  :----. .:::------:   #@@@@-   -----   [email protected]@@@%+-   ..----------:.  -----  :::::-----   [email protected]@%.  .----:   *@@@@@@:   --------:::::.      .---%@@@@@@
//@@@@%.           :----. :---------:   #@@@@-   -----   [email protected]@@@@@+     ----------   .----- .----------   [email protected]@%.  .----:   *@@@@@@:   -------------:          #%@@@@@
//@@@@%.           :-----:---------     #@@@@-   -----   [email protected]@@@@@+     --------:   :------:-----------   [email protected]@%.  .----:   *@@@@@@:    :------------:::       .:%@@@@
//@@@@%:........   :--------------:     #@@@@-   -----   [email protected]@@@@@+.    --------.   ------------------:   [email protected]@%.  .----:   *@@@@@@:    .---------------.       .%@@@@
//@@@@@%%%%%%%%*   :-------------       #@@@@-   -----   [email protected]@@@@@@@:    .------. :------------------.    [email protected]@%.  .----:   *@@@@@@:      :----------------:    .%@@@@
//@@@@@@@@@@@@@*   :----------:::     .-#@@@@-   -----   [email protected]@@@@@#+.   .:------. :---------------:::     [email protected]@%.  .----:   *@@@@@@+-     .:::::-----------:.   .%@@@@
//@@@@@@@@@@@@@*   :---------:        [email protected]@@@@@-   -----   [email protected]@@@@@=     --------. :---------------        [email protected]@@.  .----:   *@@@@@@@%          .-------------.  .%@@@@
//@@@@@@@@@@@@@*   :------...       .+#@@@@@@-   -----   [email protected]@@@@@+     --------::---------.......        .---   .----:   :--------           ...----------.  .%@@@@
//@@@@@@@@@@@@@*   :------          [email protected]@@@@@@@-   -----   [email protected]@@@@@+     -------------------                      .----:                          ----------.  .%@@@@
//@@@@@@@@@@@@@*   :----:        +##%@@@@@@@@-   -----   [email protected]@@@@@+   :-----------.  .-----                      .----:                 +#          :------.  .%@@@@
//@@@@@@@@@@@@@*   :----.     ...#@@@@@@@@@@@-   -----   [email protected]@@@%#=   ------------.  .-----                      .----:                 +#          .:-----.  .%@@@@
//@@@@@@@@@@@@@*   :----.    :%%%%@@@@@@@@@@@-   -----   [email protected]@@@#     ---------------------          :----:      .----: .-----------:                 :----.  .%@@@@
//@@@@@@@@@@@@@*   :----.   [email protected]@@@@@#++++++++:   -----   :++++=     ---------------------          :----:      .-----.:-----------:                .:----.  .%@@@@
//@@@@@@@@@@@@@*   :----.   %@@@@@@@*            -----              ---------------------          :----:      .------------------:               .------.  .%@@@@
//@@@@@@@@@@@@@*   :----.   %@@@@@@@*            -----            .:-----..--------------:.       ::----:      .------------------:   .::::.   ::::------.  .%@@@@
//@@@@@@@@@@@@@*   :----.   %@@@@@@@*            -----            :------  ---------------:      .------:      .------------------:   :----.   ----------.  .%@@@@
//@@@@@@@@@@@@@*   :----.   %@@@@@@@*   :-----------------------. :------.  .---------------------------:      .----------            :-----:::--------:    .%@@@@
//@@@@@@@@@@@@@*   :----.   %@@@@@@@*   :-----------------------: :------.   :------:-------------------:      .::::::::::            :---------------:.    .%@@@@
//@@@@@@@@@@@@@*   :----.   %@@@@@@@*   :-----------------------: :------.    .----: .------------------:                             :---------------      .%@@@@
//@@@@@@@@@@@@@*   :----.   %@@@@@@@*   :-----------------------: :------.    .::::. .:--------------:.:.                    .----:   :-----------:...     -=%@@@@
//@@@@@@@@@@@@@*   :----.   %@@@@@@@*   ------------------------: :------.             :-------------                        [email protected]@@@#   :-----------.        #@@@@@@
//@@@@@@@@@@@@@*    ....    %@@@@@@@*    .......................   ......               .............       +****************#@@@@*    ...........       -*%@@@@@@
//@@@@@@@@@@@@@*            %@@@@@@@*                                                                       #@@@@@@@@@@@@@@@@@@@@@*                      [email protected]@@@@@@@
//@@@@@@@@@@@@@*            %@@@@@@@*                                       .######+                    :###%@@@@@@@@@@@@@@@@@@@@@*                   ###%@@@@@@@@
//@@@@@@@@@@@@@#::::::::::::%@@@@@@@*:::::::::::::::::::::::::::::::::::::::[email protected]@@@@@#::::::::::::::::::::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@#:::::::::::::::::::%@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


contract XtremePixels is ERC721r, ERC2981, Ownable, ReentrancyGuard, RevokableDefaultOperatorFilterer {
    using Counters for Counters.Counter;
    using Strings for uint256; //allows for uint256var.tostring()

    uint256 public MAX_MINT_PER_WALLET_PRESALE = 5;
    uint256 public MAX_MINT_PER_WALLET_SALE = 5;

    bytes32 public presaleMerkleRoot;
    string private baseURI;
    bool public enablePresale = false;
    bool public enableSale = false;

    struct User {
        uint256 countPresale;
        uint256 countSale;
    }

    mapping(address => User) public users;

    constructor(string memory __baseURI) ERC721r("XTREME PIXELS", "XPIX", 25_000) {
        _setDefaultRoyalty(0x28EbE06F78077ee754d3395BDEFa3E68b363D52d, 1000);
        baseURI = __baseURI;
    }

    function mintPresale(bytes32[] calldata _merkleProof, uint256 _amount) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(enablePresale, "Presale is not enabled");
        require(
            users[msg.sender].countPresale + _amount <= MAX_MINT_PER_WALLET_PRESALE,
            "Exceeds max mint limit per wallet");
        require(MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf), "Proof is invalid");
        _mintRandomly(msg.sender, _amount);
        users[msg.sender].countPresale += _amount;
    }

    function mintSale(uint256 _amount) public {
        require(enableSale, "Sale is not enabled");
        require(
            users[msg.sender].countSale + _amount <= MAX_MINT_PER_WALLET_SALE,
            "Exceeds max mint limit per wallet");
        _mintRandomly(msg.sender, _amount);
        users[msg.sender].countSale += _amount;
    }

    /// ============ INTERNAL ============
    function _mintRandomly(address to, uint256 amount) internal {
        _mintRandom(to, amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// ============ ONLY OWNER ============
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setEnablePresale(bool _enablePresale) external onlyOwner {
        require(enablePresale != _enablePresale, "Invalid status");
        enablePresale = _enablePresale;
    }

    function setEnableSale(bool _enableSale) external onlyOwner {
        require(enableSale != _enableSale, "Invalid status");
        enableSale = _enableSale;
    }

    function setMaxMintPerWalletPresale(uint256 _limit) external onlyOwner {
        require(MAX_MINT_PER_WALLET_PRESALE != _limit, "New limit is the same as the existing one");
        MAX_MINT_PER_WALLET_PRESALE = _limit;
    }

    function setMaxMintPerWalletSale(uint256 _limit) external onlyOwner {
        require(MAX_MINT_PER_WALLET_SALE != _limit, "New limit is the same as the existing one");
        MAX_MINT_PER_WALLET_SALE = _limit;
    }

    function setPresaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        presaleMerkleRoot = _merkleRoot;
    }

    function ownerMint() external onlyOwner {
        require(_ownerOf(1) == address(0), "The #1 token has been minted.");
        _mintAtIndex(msg.sender, 1);
    }

    /// ============ ERC2981 ============
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721r, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        ERC721r._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /// ============ OPERATOR FILTER REGISTRY ============
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view override(UpdatableOperatorFilterer, Ownable) returns (address) {
        return Ownable.owner();
    }
}