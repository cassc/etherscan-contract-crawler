// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "ThreePerWallet.sol";
import "Ownable.sol";
import "ERC721.sol";
import "IERC721.sol";

import "IOpenDAO.sol";
/***************************************************************************************************
oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo+/::://+ooooooooooooo
oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo/-`       `./ooooooooooo
oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo/.             .+ooooooooo
ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo/`               `+oooooooo
ooooooooooooooooooooooooooooooooooooooossyyhhddddmmmmmddddhhyyssoooooooo+`                 ./++ooooo
ooooooooooooooooooooooooooooooooosyhdmNNNNNmmmmmddddddddmmmmNNNNNmdhyso/-                   ```-/ooo
ooooooooooooooooooooooooooooosydNNNmmddhhdddmddddddddddddddhhysyhhdmNNmo`                       `:oo
ooooooooooooo++:-....-:++oosdNMMd+/:yNMMMMNmdhhyyyyyyyyyyhhdmMMNmo-:/oNMh                         /o
oooooooooooo/.          ./oNMNMMdyo/ossyyyhddmmNmmmmmmmmmmmmNmhs+:::/sNMh                         `:
ooooooooooo-              +MMoshdNNMMNmdhysoo+/////++++oooooosyhhdmNMNd+`                           
oooooooooo/               /MMo::::/+oshNMMMMMMMMMMMMMMMMMMMMMMMMmdhyo.                              
oooo+/:::/-             `.-NMm::::::/yNMNhs+++oooossssoooo++sdMMmyooo+:.``                      ``..
o/.`                  omMMMMMMy::::sNMNy+/////////////////////+hMMmsooooooo+++/////////////+++oooooo
.                    hMNs++ohMMs:+mMNy+/////////////////////////odMMhooooooooooooooooooooooooooooooo
                    -MMs:::::yMMhNMmo////////////////////////////+yMMdoooooooooooooooooooooooooooooo
                    -MMs::::::smMMd+/////////////////////////////++yMMdooooooooooooooooooooooooooooo
                     dMm/:::::+NMd+//////////osys+//////////////smNNMMMhoooooooooooooooooooooooooooo
                     -mMd/::::mMN+/////////+hNNMMmo////////////sMMyyMMMMsooooooooooooooooooooooooooo
                      -dMNs/:sMMs//////////yMM/-hMNo///////////NMd .MMMMdooooooooooooooooooooooooooo
`                     `hMMMmomMm///////////NMd  `MMh///////////mMm`.MMMMNooooooooooooooooooooooooooo
+/:-----------------..oMMshNMMMy///////////mMm` .MMh///////////oNMmmMNdMMsoooooooooooooooooooooooooo
oooooooooooooooooooooohMM+:/hMMs///////////sNMmymMNo///+++syyhhhdNMNhoyMMsoooooooooooooooooooooooooo
oooooooooooooooooooooosMMh::sMMo////////////+ydddy+/+oydNMMNNNmmmNNMMNNMMooooooooooooooooooooooooooo
oooooooooooooooooooooooyMMh:sMMo//////////////////+smMMmhyo+//////+yyymMMdoooooooooooooooooooooooooo
ooooooydmNMMMNNNmmdhysooyNMmhMMs/////////////////omMMho/oNNo//////yMM+/sNMmooooooooooosssyyssooooooo
ooooohMMy+///++oshdNMMNdoohMMMMh/////////////////smd+///oMMo//////omd+//hMMoooooyhmNMMMMMMMMMNdooooo
ooooohMMs-`         ./mMNooodNMN//////////////////+//////++////////+////hMMooymMMmhs+:-..``./NMdoooo
ooooooyMMMNmhysso.    :MMyoooyMMs/////////////+s+//////////////////////+NMmodMMs-`   `.-:/+ydMMhoooo
oooooooMMmosyhhdd:    .MMhooooNMm+////////////hMN+/////////+oyhmmmdysoodMMsoMMs    `mNNNNNmhmMMooooo
ooooooohNMdsosymNd     hMNsoooyMMy////////////oNMmso++++oshNNNmdhdmNMNNMmyohMM-    /hs+/::/+mMmooooo
oooooooosNMMddhyo/     `yNNmddNMMNy+///////////ohNMNNmNNNNmdyo+///+yMMNyosyNMh     hNNmmmNNMNhoooooo
ooooooooodMM+--+dm+  ..  -ohNMMNymMmy+///////////+oyyhyyso+//////+omMNMNmNMmo`   .-..://+dMMoooooooo
oooooooooohNNNMMms--ymm. ``+NMM: .omMmy+////////////oso++/+++ooshmMNdohMMm/. --``dNmhsosdMNyoooooooo
oooooooooooosmMMdhdMMh:`/dmMMMMy   .oNMNhs+////////+mMNmmdmmNNMNNdyo///yNMy``mMh::omMMNNmhsooooooooo
oooooooooooooohmNMMMMhydMMMMyyMMo `+dMNNNMNho///////+syhdddhysso+///////sNMdssNMMNNMNhoooooooooooooo
oooooooooooosmMMMMMMMMmhhMMh//yMMohMNyssyymMNs///////////////////////////oNMMMNNdyysoooooooooooooooo
oooooooooooomMm++oshNMNyNMm+///yMMMM+dMmmMmdMMs+//////////////////////////oNMmoooooooooooooooooooooo
ooooooooooooNMd::::::omMMMo/////oNMN:NMsoNMsMMMms/////+++++////////////////sMMhooooooooooooooooooooo
oooo+/:--::/mMm:::::::+MMh///////yMMy+dmmdohMMyMMmhdNMMMNMMMMNNmdys+////////hMMyoooooooooooooooooooo
o+:`        yMM:::::::dMN+////////yNMmysshmMMm..omMMmo:::::://+oydNNdo//////+mMNoooooooooooooooooooo
/`          :MMs:::::/MMh//////////+yNMMNMMo/NN: `/hNMmy+:::::::::/omMh//////oMMdo+/:::/+ooooooooooo
             dMm:::::yMM+////////////oNMdoMd`.dd    .+hNMmho/:::::::/dMy//////dMM/`     `-+ooooooooo
             +MMy::::NMm//////////////sMMy+Nd.``      `./ymMNdyo/::::/MN++mms/oMMo        `+oooooooo
            sNMMMs::+MMy///////////////yMM//Nm:           `-ohmNNmyo+/mMo/mMm//mMm         /oooooooo
           :MMshMNs:sMMo////////////ymh+mMm -hNs`             .-+ymNNmNMhohMMo/yMM-        -/+oooooo
           +MM+:hMMohMM/////////////dMN/yMM: `oNd/`               `-/shmNNNMMh/oMM+          `/ooooo
           -MMs::os/mMm/////////////dMM/+MMo   -yNy                    `-/sNMm//MMy           `+oooo
            dMm:::::NMm/////////////hMM++MMs     -.                        yMM+/NMd            /oooo
            :MMy::::NMd/////////////hMM+oMM+                               +MMo/mMm`          .+oooo
             sMMo:::NMd/////////////hMModMN`                               /MMs/mMNo+++++////+oooooo
              yMMs::mMm/////////////yMMdMM/                                :MMs/NMmooooooooooooooooo
 ***************************************************************************************************/

contract KaijuDAO is ERC721, ThreePerWallet, Ownable{
    using Address for address;
    using Strings for uint256;

    address private signer;
    address payable public treasury;
    bool private publicGen0Sale;
    bool private publicGen1Sale;
    bool private preGen0Sale;
    
    uint16 public minted;
    //uint256 public constant MINT_PRICE_SOS_GEN0 = 50000000000000000000000000;
    uint256 public  MINT_PRICE_ETH_GEN0_PRESALE = 0.03 ether;
    uint256 public  MINT_PRICE_ETH_GEN0 = 0.04 ether;
    uint256 public  MINT_PRICE_ETH_GEN1 = 0.04 ether;
    uint256 public  MINT_PRICE_SOS_GEN0_PRESALE = 23000000000000000000000000;
    uint256 public  MINT_PRICE_SOS_GEN0 = 31000000000000000000000000;
    uint256 public  MINT_PRICE_SOS_GEN1 = 31000000000000000000000000;
    uint256 public MAX_TOKENS_GEN0 = 10000;
    uint256 public MAX_TOKENS_GEN1 = 10000;
    uint256 public MAX_AIRDROPS_GEN0 = 100;
    uint256 public MAX_AIRDROPS_GEN1 = 100;
    uint256 public remain_airdrops_gen0 = 100;
    uint256 public remain_airdrops_gen1 = 100;

    uint16 public round_gen0;
    uint16 public round_gen1;

    address[] public power_leaders;
    address[] public money_leaders;
    address[] public music_leaders;
    address[] public alien_leaders;
    address[] public zombie_leaders;

    mapping(uint256 => uint16) public traits;
    uint256[] public power_list;
    uint256[] public money_list;
    uint256[] public music_list;
    uint256[] public alien_list;
    uint256[] public zombie_list;

    IOpenDAO private openDAO;

    uint256 private accum_eth_gen0 = 0 ether;
    uint256 private accum_eth_gen1 = 0 ether;

    uint256 private accum_sos_gen0 = 0;
    uint256 private accum_sos_gen1 = 0;

    constructor(address _openDAOAddress) ERC721("ChubbyKaijuDAO", "CKAIJU"){
        openDAO = IOpenDAO(_openDAOAddress);
    }

    function initialize(uint256 supply0, uint256 supply1, uint256 airdrop0, uint256 airdrop1, address _signer, address payable _treasury) public onlyOwner {
        openDAO.approve(address(this), 1000000000000000000000000000000);
        MAX_TOKENS_GEN0=supply0;
        MAX_TOKENS_GEN1=supply1;
        MAX_AIRDROPS_GEN0 = airdrop0;
        remain_airdrops_gen0 = MAX_AIRDROPS_GEN0;
        MAX_AIRDROPS_GEN1 = airdrop1;
        remain_airdrops_gen1 = MAX_AIRDROPS_GEN1;
        signer = _signer;
        treasury = _treasury;
    }

    function _setTrait(uint256 tokenId) internal {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId)));
        if(tokenId<MAX_TOKENS_GEN0+1){
            uint16 mod = uint16(seed % 3);
            traits[tokenId] = mod;
            if(mod == 0 && power_list.length<uint256(MAX_TOKENS_GEN0/3)){
                power_list.push(tokenId);
            }else if(mod == 1 && money_list.length<uint256(MAX_TOKENS_GEN0/3)){
                money_list.push(tokenId);
            }else{
                music_list.push(tokenId);
            }
        }else{
            uint16 mod = uint16(seed % 2)+3;
            traits[tokenId] = mod;
            if(mod==3 && alien_list.length < MAX_TOKENS_GEN1/2) alien_list.push(tokenId);
            else zombie_list.push(tokenId);
        }
    }

    function airdropGEN0(address[] calldata airdropAddresses) public onlyOwner {
        require(remain_airdrops_gen0-airdropAddresses.length>=0, "Too many airdrops");
        for(uint256 i = 0; i < airdropAddresses.length; i++) {
            minted++;
            _setTrait(minted);
            _mint(airdropAddresses[i], minted);
            _autoTransfer();
        }
        remain_airdrops_gen0 -= airdropAddresses.length;
    }

    function airdropGEN1(address[] calldata airdropAddresses) public onlyOwner {
        require(remain_airdrops_gen1-airdropAddresses.length>=0, "Too many airdrops");
        for(uint256 i = 0; i < airdropAddresses.length; i++) {
            minted++;
            _setTrait(minted);
            _mint(airdropAddresses[i], minted);
            _autoTransfer();
        }
        remain_airdrops_gen1 -= airdropAddresses.length;
    }

    function preSaleETH(bytes memory signature, uint16 amount) external payable threePerWallet(msg.sender, minted+1){
        require(preGen0Sale, "preSale closed");
        require(isWhitelisted(msg.sender, signature), "Not Whitelisted");
        require(MINT_PRICE_ETH_GEN0_PRESALE * amount == msg.value, "Invalid payment amount");
        require(amount < 4, "Too many amount");
        require(minted + amount <= MAX_TOKENS_GEN0-remain_airdrops_gen0, "minted out");
        for(uint i=0; i<amount; i++){
            minted++;
            accum_eth_gen0 += MINT_PRICE_ETH_GEN0_PRESALE;
            _setTrait(minted);
            _mint(msg.sender, minted);
            _autoTransfer();
        }
    }
    function publicETH(uint16 amount) external payable threePerWallet(msg.sender, minted+1){
        if(minted<MAX_TOKENS_GEN0){
            require(publicGen0Sale, "publicGen0Sale not open");
            require(MINT_PRICE_ETH_GEN0 * amount == msg.value, "Invalid payment amount");
            require(minted + amount <= MAX_TOKENS_GEN0-remain_airdrops_gen0, "minted out");
        }else{
            require(publicGen1Sale, "publicGen1Sale not open");
            require(MINT_PRICE_ETH_GEN1 * amount == msg.value, "Invalid payment amount");
            require(minted + amount <= MAX_TOKENS_GEN0+MAX_TOKENS_GEN1-remain_airdrops_gen1, "minted out");
        } 
        require(amount < 4, "Too many amount");
        
        for(uint i=0; i<amount; i++){
            minted++;
            if(minted < MAX_TOKENS_GEN0+1) accum_eth_gen0 += MINT_PRICE_ETH_GEN0;
            else accum_eth_gen1 += MINT_PRICE_ETH_GEN1;
            _setTrait(minted);
            _mint(msg.sender, minted);
            _autoTransfer();
        }
    }
    function preSaleSOS(bytes memory signature, uint16 amount) external threePerWallet(msg.sender, minted+1){
        require(preGen0Sale, "preSale closed");
        require(isWhitelisted(msg.sender, signature), "Not Whitelisted");
        require(amount < 4, "Too many amount");
        require(minted + amount <= MAX_TOKENS_GEN0-remain_airdrops_gen0, "minted out");
        require(MINT_PRICE_SOS_GEN0_PRESALE * amount <= openDAO.balanceOf(msg.sender), "not enough balance");
        require(MINT_PRICE_SOS_GEN0_PRESALE * amount <= openDAO.allowance(msg.sender, address(this)), "low allowance");
        openDAO.transferFrom(msg.sender, address(this), MINT_PRICE_SOS_GEN0_PRESALE * amount);
        for(uint i=0; i<amount; i++){
            minted++;
            accum_sos_gen0 += MINT_PRICE_SOS_GEN0_PRESALE;
            _setTrait(minted);
            _mint(msg.sender, minted);
            _autoTransfer();
        }
    }
    function publicSOS(uint16 amount) external threePerWallet(msg.sender, minted+1){
        if(minted<MAX_TOKENS_GEN0){
            require(publicGen0Sale, "publicGen0Sale not open");
            require(minted + amount <= MAX_TOKENS_GEN0-remain_airdrops_gen0, "minted out");
            require(MINT_PRICE_SOS_GEN0 * amount <= openDAO.balanceOf(msg.sender), "not enough balance");
            require(MINT_PRICE_SOS_GEN0 * amount <= openDAO.allowance(msg.sender, address(this)), "low allowance");
        }else{
            require(publicGen1Sale, "publicGen1Sale not open");
            require(minted + amount <= MAX_TOKENS_GEN0+MAX_TOKENS_GEN1-remain_airdrops_gen1, "minted out");
            require(MINT_PRICE_SOS_GEN1 * amount <= openDAO.balanceOf(msg.sender), "not enough balance");
            require(MINT_PRICE_SOS_GEN1 * amount <= openDAO.allowance(msg.sender, address(this)), "low allowance");
        } 
        require(amount < 4, "Too many amount");
        
        openDAO.transferFrom(msg.sender, address(this), MINT_PRICE_SOS_GEN0_PRESALE * amount);
        for(uint i=0; i<amount; i++){
            minted++;
            if(minted < MAX_TOKENS_GEN0+1) accum_sos_gen0 += MINT_PRICE_SOS_GEN0;
            else accum_sos_gen1 += MINT_PRICE_SOS_GEN1;
            _setTrait(minted);
            _mint(msg.sender, minted);
            _autoTransfer();
        }
    }

    function ownerOf(uint256 tokenId) public view override(ERC721) returns (address) {
        return super.ownerOf(tokenId);
    }

    function contractURI() public pure returns (string memory) {
        //TODO change contractURI
        return "https://raw.githubusercontent.com/KaijuDAO/kaijudao/main/contracturi";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() override internal pure returns (string memory) {
        //TODO change baseURI
        return "https://raw.githubusercontent.com/KaijuDAO/kaijudao/main/tokenuri/";
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721, ThreePerWallet) {
        ThreePerWallet._mint(to, tokenId);
    }

    function setLeadersGen0(address power, address money, address music) external onlyOwner {
        power_leaders.push(power);
        money_leaders.push(money);
        music_leaders.push(music);
        round_gen0++;
    }

    function setLeadersGen1(address alien, address zombie) external onlyOwner {
        alien_leaders.push(alien);
        zombie_leaders.push(zombie);
        round_gen1++;
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    function isWhitelisted(address user, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encode(user));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "sig invalid");

        assembly {
        /*
        First 32 bytes stores the length of the signature

        add(sig, 32) = pointer of sig + 32
        effectively, skips first 32 bytes of signature

        mload(p) loads next 32 bytes starting at the memory address p into memory
        */

        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
    function setPreGen0Sale(bool isPre) public onlyOwner {
        preGen0Sale = isPre;
    }
    function setpublicGen0Sale(bool isPublic) public onlyOwner {
        publicGen0Sale = isPublic;
    }
    
    function setpublicGen1Sale(bool isPublic) public onlyOwner {
        publicGen1Sale = isPublic;
    }

    function setSupplyGen0(uint256 supply) public onlyOwner {
        MAX_TOKENS_GEN0=supply;
    }

    function setSupplyGen1(uint256 supply) public onlyOwner {
        MAX_TOKENS_GEN1=supply;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setTreasury(address payable _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setAirdropGen0(uint256 airdrop) public onlyOwner{
        MAX_AIRDROPS_GEN0 = airdrop;
    }

    function setAirdropGen1(uint256 airdrop) public onlyOwner{
        MAX_AIRDROPS_GEN1 = airdrop;
    }

    function setGen0SOSPrice(uint256 price) public onlyOwner{
        MINT_PRICE_SOS_GEN0 = price;
    }

    function setGen1SOSPrice(uint256 price) public onlyOwner{
        MINT_PRICE_SOS_GEN1 = price;
    }

    function _autoTransfer() internal {
        if(minted < MAX_TOKENS_GEN0+1){
            if(minted%1000 == 0){
                require(address(this).balance>=accum_eth_gen0);
                treasury.transfer(accum_eth_gen0/4);
                openDAO.transferFrom(address(this), treasury, uint256(accum_sos_gen0/4));
                accum_eth_gen0=0 ether;
                accum_sos_gen0=0 ;
                
            }
        }else{
            // TODO: Gen1 treasury autotransfer
            if(minted%1000 == 0){
                require(address(this).balance>=accum_eth_gen1);
                treasury.transfer(accum_eth_gen1/4);
                openDAO.transferFrom(address(this), treasury, uint256(accum_sos_gen1/4));
                accum_eth_gen1=0 ether;
                accum_sos_gen1=0 ;
            }
        }
    }

    function withdraw() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
        openDAO.transferFrom(address(this), owner(), openDAO.balanceOf(address(this)));
    }
}