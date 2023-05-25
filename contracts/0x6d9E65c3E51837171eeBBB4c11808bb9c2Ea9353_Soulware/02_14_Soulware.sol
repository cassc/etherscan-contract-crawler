// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                 -so+/:.                                          //
//                                                 /NNNNNmy-                                        //
//                                              `` /NNNNNNNmo.                                      //
//                                       `.-/+syhd./NNNNNNNNNd/    .`                               //
//                                   `.:shmNNNNNNN./NNNNNmmmmmm-   .+:`                             //
//                                 .+hmNNNNNNNNNNN.:NNNy:--...-`     +y:                            //
//                               -smNNNNNNNNNNNNNN..mmmo              :yo`                          //
//                             .yNNNNmmmNNNNNNNmmm. ```                 +h`                         //
//                            +mNmohyyy:hNNNosssyy`     /sssyys.         .`                         //
//                          `smNN/dNNNm-yyyy:NNNNN.     sNNNNNNy                                    //
//                         .s/hhsyNNNNNmmNNNNNNNNN.:dmmmNNNNNNNN/      ..                           //
//                        `mNyhmNNNNNNNNNNNNNNNNNN./NNNNNNNNNNNNo       +yo                         //
//                        yNNNNNNNNNNNNNNNNNNNNNNN./NNNNNNNNNNNNo       .NN/                        //
//                       .NNNNNNNNNNNNNNNNNNNNNNNN./NNNNNNNNNNNN+        yNd                        //
//                      :hNNNNNNNNNNNNNNNNNNNNNNNN./NNNNNNNNNNNN.        :NN.                       //
//                     +NNNNNNNNNNNmdhhhhhdmmNNNNN./NNNhyoo++//:         `NN/                       //
//                     /NNNNNNNNmy/-``    `.-/dNNN./NNo                   dNs                       //
//                    `oddNNNNNm/`.-://:-`  `+mNNN./Nd`     `.:::-`       sNh                       //
//                   shmhhNNNNNsshmNNNNNNds-yNNNNN./N-    .ohNNNmmh       oNh-+:-                   //
//                   :yNNNNNNNNNNNNNNNNNNNNNNNNNNN./m`   /mmds/:--.       oNd+odh                   //
//                   +hyNNNNNNNNNNNNNNNNNNNNNNNNNN./No  :h+:/shdmmdho.    /NoyNNy                   //
//                   dNdhNNNNNNNNNNNNNNNNNNNNNNNNN./NN/ ..yNNNNNNNNNNN/   /NmddNy                   //
//                  :NNNNNNNNmo-+yhhyysso+:`sNNNNN./NNN:`.-/ossyyyyss+`   yNN.:Nd                   //
//                  .dNNNNNNNNNo. ````   .`+NNNNNN./NNNm/ohs+/-.         +NNN. oN`                  //
//                  :hNNdNNNNNNNmhso+++ssodNNNNNNd`-mNNNNs:yNNdhyssossyy+NNm/. -N`                  //
//                  `mNNdNNNNNNNNNNNNmhydNNNNNNNho`.odNNNNdo/smNNNNNNNNNNNNNssymh                   //
//                   :hmmdNNNNNNNNNNNNNNNNNNNNNNNN./NNNNNNNNmho+sshdNNNNNNNNy+my.                   //
//                    `../NNNNNNNNNNNNNNNNNNNNNNNN./NNNNNNNNNNNmddhdNNNsdNNN...`                    //
//                       -NNNNNNNNNNNNNNNNNNNNNNNN./NNNNNNNNNNNNNNNmmh/ sNNm                        //
//                       `mNNNNNNNNNNNNNNNNNNNNNNN./NNNNNNmhs+/::---.   +NNy                        //
//                        oNNNNNNNNNNNNNNNNNNNNNmd.:dmmNms-             oNN:                        //
//                        `mNNNNNNNNNNNNNNNNNNNdys`.+/-/-               yNh                         //
//                         :NNNNNNNNNNNNNNNNNNNNNN.:h-                 -Nd.                         //
//                          /dhNNNNNNNNNNNNNNNNNNN.`                  :mh.                          //
//                           -h+sNNNNNNNNNNNNNNNNN.                 .sm/                            //
//                            `sy:/hNNNNNNNNNNNNNN.               .smo`                             //
//                              .sy/-odNNNNNNNNNNN.             -yh+`                               //
//                                `/ys/:odNNNNNNNN.          -oyo-`                                 //
//                                  `-oys+/odNNNNN.      `:oys:`                                    //
//                                     `.+ssooshdm.  `-/ss+-`                                       //
//                                         `-/osyy`-ss+:.`                                          //
//                                             `.. `.                                               //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721.sol";
import "./WithdrawFairly.sol";

contract Soulware is ERC721, Ownable, WithdrawFairly {

    uint256 public constant RESERVE_NFT = 1;
    uint256 public constant START_AT = 1;
    uint256 public constant HASH_SIGN = 98545;
    int16 public constant MAX_FREE = 505;
    int8 public constant MAX_TRUE = 3;
    int8 public constant MAX_CERT = 6;

    struct Sale {
        uint64 start;
        uint64 end;
        int16 maxPerWallet;
        uint8 maxPerTx;
        uint256 price;
        bool paused;
    }

    mapping(string => mapping(address => uint16)) balanceSale;

    struct AutoBurn{
        uint64 start;
        uint16 fastBurnedMax;
        uint32 fastBurnDuration;
        uint16 slowBurnedMax;
        uint32 slowBurnDuration;
        uint16 maxBurned;
        uint16 maxSupply;
    }

    string public baseTokenURI;

    AutoBurn public autoBurn;
    IERC721 public originAddress;
    address public signAddress;
    uint16 public totalMintTracked;
    uint16 public reservedTracked;
    uint16 public mintTracked;
    uint16 public freeTracked;
    uint16 public burnedTracker;

    mapping(string => Sale) public sales;
    mapping(uint256 => bool) private signatureIds;
    mapping(uint16 => bool) public freeClaimOriginIds;

    event EventSaleChange(string _name, Sale _sale);
    event EventMint(uint256 _token);

    constructor(string memory baseURI, address _originAddress, address _signAddress) ERC721("Soulware", "SW") WithdrawFairly() {
        setBaseURI(baseURI);
        setOriginAddress(_originAddress);
        setSignAddress(_signAddress);

        setSale("PRESALES", Sale(1639166400, 1639252799, MAX_CERT,   6, 0.075 ether, false));
        setSale("PUBLIC",   Sale(1639252800, 1954699200, -1,         5, 0.08 ether,  false));
        setSale("FREE",     Sale(1639339200, 1639425599, MAX_FREE,   15,0 ether,   false));

        setAutoBurn(AutoBurn(1639252920, 1500, 3 hours, 3450, 7 days, 4950, 9902));
    }

    //******************************************************//
    //                     Modifier                         //
    //******************************************************//
    modifier isOpen(string memory _name, uint8 _count){

        require(saleIsOpen(_name), "Sale not open");
        if(bytes(_name).length == bytes("FREE").length){
            require(int16(freeTracked) <= MAX_FREE, "SoldOut!");
        }else{
            require(publicMinted() + uint16(_count) <= uint16(maxSupply(0)), "SoldOut!");
        }

        require(_count <= sales[_name].maxPerTx, "Max per tx limit");
        require(msg.value >= sales[_name].price * _count, "Value limit");

        if(sales[_name].maxPerWallet > -1){
            require(int16(balanceSale[_name][_msgSender()] + uint16(_count)) <= int16(sales[_name].maxPerWallet), "Max per wallet limit");
            balanceSale[_name][_msgSender()] += uint16(_count);
        }
        _;
    }

    //******************************************************//
    //                     Sales logic                      //
    //******************************************************//
    function setSale(string memory _name, Sale memory _sale) public onlyOwner{
        sales[_name] = _sale;
        emit EventSaleChange(_name, _sale);
    }
    function pauseSale(string memory _name, bool _pause) public onlyOwner{
        sales[_name].paused = _pause;
    }
    function saleIsOpen(string memory _name) public view returns(bool){
        return sales[_name].start > 0 && block.timestamp >= sales[_name].start && block.timestamp <= sales[_name].end  && !sales[_name].paused;
    }

    //******************************************************//
    //                     Mint                             //
    //******************************************************//

    function preSalesMint(uint8 _count, bool _isCert, uint256 _signatureId, bytes memory _signature) public payable isOpen("PRESALES", _count) {

        address wallet = _msgSender();

        if(!_isCert){
            require(int16(balanceSale["PRESALES"][wallet]) <= int16(MAX_TRUE), "Max per wallet limit (PRESALES)");
        }
        require(signatureIds[_signatureId] == false, "Signature already used");
        require(checkSignature(wallet, _isCert, _count, _signatureId, _signature) == signAddress, "Signature error : bad owner");
        signatureIds[_signatureId] = true;

        _mintTokens(_count);

    }
    function publicSalesMint(uint8 _count) public payable isOpen("PUBLIC", _count) {

        _mintTokens(_count);

    }
    function freeSalesMint(uint16[] memory _originIds) public payable isOpen("FREE", uint8(_originIds.length * 5)) {

        for(uint8 i = 0; i < _originIds.length; i++){
            require(originAddress.ownerOf(_originIds[i]) == _msgSender(), "Not owner of this Origin");
            require(freeClaimOriginIds[_originIds[i]] == false, "Origin already claim");
            freeClaimOriginIds[_originIds[i]] = true;

            for(uint8 k = 0; k < 5; k++){
                freeTracked += 1;
                _mintToken(reservedTracked + freeTracked);
            }
        }
    }
    function reserve(uint16 _count) public onlyOwner {
        require(reservedTracked + _count <= RESERVE_NFT, "Exceeded RESERVE_NFT");
        for (uint16 i = 0; i < _count; i++) {
            reservedTracked += 1;
            _mintToken(reservedTracked);
        }
    }
    function mintNotClaimTokens(uint16 _count) public onlyOwner{
        require(!saleIsOpen("FREE"), "Free claim is still open");

        for (uint16 i = 0; i < _count; i++) {
            freeTracked += 1;
            _mintToken(reservedTracked + freeTracked);
        }
    }
    function _mintToken(uint16 _tokenId) private {
        totalMintTracked += 1;
        _safeMint(_msgSender(), _tokenId);
        emit EventMint(_tokenId);
    }
    function _mintTokens(uint8 _count) private {
        for(uint8 i = 0; i < _count; i++){
            mintTracked += 1;
            _mintToken(reservedTracked + uint16(MAX_FREE) + mintTracked);
        }
    }
    function checkSignature(address _wallet, bool _isCert, uint256 _count, uint256 _signatureId, bytes memory _signature) public pure returns(address){
        return ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(_wallet, _isCert, _count, _signatureId, HASH_SIGN)))), _signature);
    }

    //******************************************************//
    //                      Setters                         //
    //******************************************************//
    function setOriginAddress(address _originAddress) public onlyOwner{
        originAddress = IERC721(_originAddress);
    }
    function setSignAddress(address _signAddress) public onlyOwner{
        signAddress = _signAddress;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    function setAutoBurn(AutoBurn memory _autoBurn) public onlyOwner {
        autoBurn = _autoBurn;
    }

    //******************************************************//
    //                      Getters                         //
    //******************************************************//
    function maxSupply(uint256 _timestamp) public view returns(uint256){
        uint256 timestamp = _timestamp > 0 ? _timestamp : block.timestamp;

        if(timestamp < autoBurn.start) {
            return autoBurn.maxSupply;
        }
        unchecked{
            uint256 fastStart = uint256(autoBurn.start);
            uint256 fastBurnDuration = uint256(autoBurn.fastBurnDuration);
            uint256 slowStart = fastStart + fastBurnDuration;
            uint256 slowBurnDuration = uint256(autoBurn.slowBurnDuration);
            uint256 maxBurned = uint256(autoBurn.maxBurned);

            uint256 fastDuration = _min(timestamp, fastStart + fastBurnDuration) - fastStart;
            uint256 slowDuration = _min(timestamp, slowStart + slowBurnDuration) - slowStart;

            slowDuration = timestamp >= slowStart ? slowDuration : 0;

            uint256 burned = fastDuration * ((uint256(autoBurn.fastBurnedMax) * 1000 / fastBurnDuration) + 1) / 1000;
            burned += slowDuration * ((uint256(autoBurn.slowBurnedMax) * 1000 / slowBurnDuration) + 1) / 1000;

            if(burned > maxBurned){
                burned = maxBurned;
            }

            return _max(totalMintTracked, autoBurn.maxSupply - uint16(burned));
        }
    }
    function totalSupply() public view returns (uint256) {
        return totalMintTracked - burnedTracker;
    }
    function publicMinted() public view returns (uint16) {
        return reservedTracked + uint16(MAX_FREE) + mintTracked;
    }
    function price(string memory _name, uint256 _count) public view returns(uint256){
        return sales[_name].price * _count;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256 key = 0;
        uint256[] memory tokensId = new uint256[](tokenCount);
        if(tokenCount == 0) return tokensId;

        for (uint256 i = START_AT; i <= autoBurn.maxSupply; i++) {
            if(rawOwnerOf(i) == _owner){
                tokensId[key] = i;
                key++;
                if(key == tokenCount){break;}
            }
        }
        return tokensId;
    }
    function minted(string memory _name, address _wallet ) public view returns(uint16){
        return balanceSale[_name][_wallet];
    }
    function isFreeClaimed(uint16 _tokenId) public view returns (bool){
        return freeClaimOriginIds[_tokenId];
    }
    function _max(uint256 a, uint256 b) private pure returns (uint256){
        return a < b ? b : a;
    }
    function _min(uint256 a, uint256 b) private pure returns (uint256){
        return a > b ? b : a;
    }

    //******************************************************//
    //                      Burn                            //
    //******************************************************//
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner nor approved");
        burnedTracker += 1;
        _burn(tokenId);
    }

}