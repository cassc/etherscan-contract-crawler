// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract FarmerCheems is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable  {
    uint256 public _tokenIds;
    uint256 public price = 100000000000000000;

    event FarmersManufactured(address to, uint256 quantity);

    bytes4 ERC721_RECEIVED = 0x150b7a02;

    address public EmergencyAddress;
    address public Oracle;
    bool public transferFarmEnabled;
    uint256 public farmingPeriod;

    address public Cinu;
    uint public deposits;
    uint256 public stakeRequired = 500000 * 10 ** 9;

    mapping ( uint256 => Farm ) public Farms;
    mapping ( address => uint256[] ) public userFarms;
    mapping ( address =>uint256 ) public  userFarmCount;
    uint256 public FarmCount=0;

    mapping ( address => uint256[] ) public usersFarmers;
    mapping ( uint256 => uint256 ) public FarmerPosition;

    mapping ( uint256 => uint256 ) public FarmerArrayPosition;
    mapping ( uint256 => uint256 ) public FarmArrayPosition;

    uint256 public globalfarmerproduction;
    uint256 public globalfarms;

    struct Farm {
       address _owner;
       uint256 _cinustaked;
       uint256 _timeofexpiration;
       uint256 _timeunitslocked;
       uint256 _timefarminitiated;
       uint256 _lastfarmersminted;
       uint256 _farmersminted;
       uint256 _periodproductionrate;
       uint256 _periodsmanufactured;
       bool    _status;
    }

    string public  contractURIstorefront = '{ "name": "Farmer Cheems", "description": "Farmer Cheems", "image": "", "external_link": "", "seller_fee_basis_points": 300, "fee_recipient": "0x42A1DE863683F3230568900bA23f86991D012f42"}';
    string public _tokenURI = '{"description":"Farmer Cheems ","external_url":"","image":"","name":"Farmer Cheems" ,"seller_fee_basis_points": 500, "fee_recipient": "0x42A1DE863683F3230568900bA23f86991D012f42" }';

    uint256 public royaltyPerc;
    address payable public royaltyContract;

    constructor(address cinuAddress) ERC721("Farmer Cheems", "Farmer Cheems") {
        EmergencyAddress = msg.sender;
        farmingPeriod = 60 days;
        royaltyContract = payable(msg.sender);
        Cinu = cinuAddress;
    }


    function setCinu ( address _cinu ) public onlyOwner {
        Cinu = _cinu;
    }

    function setPrice ( uint256 _price ) public onlyOwner {
        price = _price;
    }

    function setOracle ( address _oracle ) public onlyOwner {
        Oracle = _oracle;
    }



    function setCinuStakeRequired ( uint256 _stakerequired ) public onlyOwner {
         require ( _tokenIds == 0,"Too Late" );
         stakeRequired = _stakerequired;
    }



    function emergencyWithdrawAnyToken( address _address) public OnlyEmergency {
        IERC20 _token = IERC20(_address);
        _token.transfer( msg.sender, _token.balanceOf (address(this)) );
    }

    function emergencyWithdrawBNB() public OnlyEmergency {
       payable(msg.sender).transfer( address(this).balance );
    }



    function onERC721Received( address _operator, address _from, uint256 _tokenId, bytes memory _data) public view returns(bytes4){
        _operator; _from; _tokenId; _data;
        return ERC721_RECEIVED;
    }

    function setTokenURI ( string memory _uri ) public onlyOwner {
        _tokenURI = _uri;
    }



    function setStoreJSON ( string memory _uri ) public onlyOwner {
        contractURIstorefront = _uri;
    }

    function setTokenURIEngine ( uint256 tokenId, string memory __tokenURI) public onlyOwner {
        _setTokenURI( tokenId, __tokenURI);
    }

    function setTokenURIEngineByOracle ( uint256 tokenId, string memory __tokenURI) public onlyOracle {
        _setTokenURI( tokenId, __tokenURI);
    }


    function FarmTransferToggle () public onlyOwner {
        transferFarmEnabled = !transferFarmEnabled;
    }

    function transferFarm ( address _owner , uint256 _farm, address _newowner ) public  {
        require ( Farms[_farm]._owner == _owner, "Not rightful owner" );
        require ( transferFarmEnabled , "Not Enabled ");
        Farms[_farm]._owner = _newowner;

        userFarmCount[_owner]--;
        uint256 pos = FarmArrayPosition[_farm];

        userFarms[_owner][pos] = userFarms[msg.sender][userFarms[msg.sender].length-1];
        FarmArrayPosition[userFarms[_owner][pos]] = pos;
        userFarms[_owner].pop();

        userFarms[_newowner].push(_farm);
        FarmArrayPosition[_farm] =  userFarms[_newowner].length - 1;
        userFarmCount[_newowner]++;
    }


    function contractURI() public view returns (string memory) {
        return contractURIstorefront;
    }



    function mintFarmers( uint256 _farm ) public payable {


        require ( Farms[ _farm]._periodsmanufactured < Farms[ _farm]._timeunitslocked );

        if ( Farms[ _farm]._farmersminted != 0 )  Farms[ _farm]._periodsmanufactured++;


        require ( Farms[ _farm]._owner == msg.sender  );
        require ( Farms[ _farm]._status == true );
        require ( block.timestamp > Farms[ _farm]._lastfarmersminted + farmingPeriod, "manufacturing process not complete" );


        for ( uint i = 0; i < Farms[ _farm]._periodproductionrate; i++ ) {
            _tokenIds++;
            uint256 newTokenId = _tokenIds;
            _safeMint( msg.sender , newTokenId);
            _setTokenURI(newTokenId, _tokenURI);
            usersFarmers[msg.sender].push(newTokenId);
            FarmArrayPosition[newTokenId] = usersFarmers[msg.sender].length -1;
            Farms[_farm]._farmersminted++;

        }
        Farms[_farm]._lastfarmersminted = block.timestamp;
        emit FarmersManufactured(msg.sender, Farms[ _farm]._periodproductionrate );
    }



    function getUsersFarmers ( address  _user ) public view returns(uint256[] memory){
        return usersFarmers[_user];
    }

    function manufactureUnits( uint256  _timeunitslocked, uint256 _units ) public pure returns(uint256){
        return _timeunitslocked * _units;
    }

    function getUserFarms(address _user ) public view returns(uint256[] memory) {
        return userFarms[_user];
    }



    function stakeCinu(  uint256 _timeperiod ) public payable {
        require ( msg.value == price, "Not enough native paid");
        uint256 _units = 1;
        require ( manufactureUnits( _timeperiod, _units ) <= 12 );

        require ( _timeperiod > 0 && _timeperiod <=12);

        deposits += stakeRequired;
        IERC20 _token = IERC20(Cinu);
        _token.transferFrom( msg.sender, address(this) , stakeRequired );
        FarmCount++;
        Farms[FarmCount]._owner = msg.sender;

        Farms[FarmCount]._timeofexpiration =  block.timestamp + ( farmingPeriod * _timeperiod);
        Farms[FarmCount]._timeunitslocked =   _timeperiod;
        Farms[FarmCount]._cinustaked = stakeRequired;
        Farms[FarmCount]._timefarminitiated = block.timestamp;
        Farms[FarmCount]._lastfarmersminted = 0;
        Farms[FarmCount]._farmersminted = 0;

        Farms[FarmCount]._periodproductionrate =  _timeperiod;
        Farms[FarmCount]._status = true;

        userFarms[msg.sender].push(FarmCount);
        userFarmCount[msg.sender]++;
        FarmArrayPosition[FarmCount] =  userFarms[msg.sender].length - 1;


        globalfarmerproduction += Farms[FarmCount]._periodproductionrate;
        globalfarms++;
    }

    function royaltyInfo( uint256 _tokenId, uint256 _salePrice ) public  view returns ( address receiver, uint256 royaltyAmount ){
        _tokenId;
        receiver = royaltyContract;
        royaltyAmount = _salePrice * royaltyPerc / 100;

    }

    function setRoyaltyPercent ( uint256 _perc ) public OnlyEmergency {
        royaltyPerc = _perc;
    }


    function unstakeCinu ( uint256 _farm ) public  {

        require ( Farms[ _farm]._owner == msg.sender );
        require ( Farms[ _farm]._status == true );

        require ( block.timestamp > Farms[ _farm]._timeofexpiration  , "time committed not yet fulfilled" );
        require ( Farms[ _farm]._periodsmanufactured >= Farms[ _farm]._timeunitslocked );

        Farms[_farm]._lastfarmersminted = block.timestamp;
        Farms[_farm]._status = false;

        uint256 _stake = Farms[_farm]._cinustaked;
        Farms[_farm]._cinustaked = 0;

        globalfarmerproduction = globalfarmerproduction - Farms[_farm]._periodproductionrate;
        globalfarms--;
         IERC20 _token = IERC20(Cinu);
        _token.transfer( msg.sender, _stake );
        deposits -= Farms[_farm]._cinustaked;
    }

    function burn(uint256 tokenId) public onlyOwner {

        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        uint256 pos = FarmerArrayPosition[tokenId];

        usersFarmers[msg.sender][FarmerArrayPosition[tokenId]] = usersFarmers[msg.sender][ usersFarmers[msg.sender].length -1 ]  ;
        FarmerArrayPosition[usersFarmers[msg.sender][ usersFarmers[msg.sender].length -1 ]] = pos;
        usersFarmers[msg.sender].pop();
        _burn(tokenId);
    }



    function transfer(address from, address to, uint256 tokenId) public {
       popFarmer ( from, to, tokenId );
       _transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public  override {

        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        popFarmer ( from, to, tokenId );
       _transfer(from, to, tokenId);
    }

    function popFarmer (address from, address to, uint256 tokenId ) internal {
       usersFarmers[to].push(tokenId);
       uint256 pos = FarmerArrayPosition[tokenId];
       usersFarmers[from][FarmerArrayPosition[tokenId]] = usersFarmers[from][ usersFarmers[from].length -1 ]  ;
       FarmerArrayPosition[usersFarmers[from][ pos ]] = pos;

       usersFarmers[from].pop();
       FarmerArrayPosition[tokenId] = usersFarmers[to].length -1;
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }


    modifier onlyOracle() {
        require( msg.sender == Oracle, "Oracle Only");
        _;
    }


    modifier OnlyEmergency() {
        require( msg.sender == EmergencyAddress, " Emergency Only");
        _;
    }
}