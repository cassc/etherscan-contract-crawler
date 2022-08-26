// SPDX-License-Identifier: MIT
//
//   ▄▄▄▄                          ╓▄▄▄▄              ██        ▄▄▄▄▄▄▄
//   ▐██ ╓▄▄▄▄ ▄█▄██▄██▄  ▀██▄╒█▀  ██▄ ▀ ▄▄█▄▄'██▄▄▄▄,▄▄  ▄█▄▄  ╙▀ ██▀ ▄▄▀▄▄ ,▄▌█▄
//   ▐██▐██▄██ ██ ╟█▌ ██   ╙███    ╨▀███ ██ ██▌██▌ ██ ██▌██ ^▀}   ██▀  █▌ ╟█ ██ ╟██
//   ▐██└██▄▄▄ ██ ╟█▌ ██   ▄▀██▌  ▐█  ██ ██ ██ ██▌ ██ ██▌██▄▄▄  ╓██▀   ██ ╟█ ██ ╟██
// ▄▄▐█▀  ▀▀▀  ▀▀ ▀▀▀ ▀▀▀ ▀▀  ▀▀▀├ ▀▀▀▀   ▀▀▀  ▀▀▀ ▀▀ ▀▀▀ ▀▀▀   ▀▀▀▀▀▀  ▀▀▀   ▀▀▀▀
//  ▀▀              ▀██▀█▄▀█▌▀█▄ª██▀▓▌▄█▀█ ▓█▌▀█ª██▄ ▓ █▀██▀█ █▀▀█
//                   ██,██ █▌▄█▀ ██▄▌ ███▄ ╟█▌▄  █▀██╟   ██   ██▄▄
//                   ██▀   █▌▐██ ██ ▄ ▄ ╙█▌╟█▌ ▄ █ ╙██   ██  ▄   █
//                  ▀▀▀▀  ▀▀▀ ▀▀┘▀▀▀▀┘╙▀▀▀ ╙▀▀▀╙ ▀╙  ▀╙ ▀▀▀▀ ╙▀▀▀╙
//                                    ,,╓╔╦╦╦╦M╦╗╗╗╓,
//                          ,╓╦φ╠╠▒▒╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠▒╗
//                      ,╦▒╠╠╠╠╠╬▒╠╠╬╬╬╠╬╬╠╓Γ╙╙╙ ╙╙╙╬╠╠╠╠╬╗,
//                    ╔╠╠╠╠╠╠╩╙╙,╔╦φ╬╠╠▒╠╠╠╠╠╠╠╠╠╠▒╗▄ ╙╬╠╬╠╠╠╗╖
//                 ╓φ╠╠╠╠╝╙ ,φ╠╠╠╠╠╠╠╠╩╜╙╙╙╙╚╩╝╬╠╠╠╠╠╠╬▒╦╙╚╠╠╬╬╠▒
//               ╔╠╠╠╠╠╩ ,φ╠╠╠╠╠╩╙╙    ,╓╔╦╦╦╦,   `╙╬╠╠╠╠╠▒╓╙╚╬╠╠╬▒,
//             ╔╠╠╠╠╠╙ ╔╬╠╠▒╠╩╙  ╓╦▒╩░░░░░░░░░░░▒▒≥,   ╙╠╠╠╠╬╦ ╚╬╬╬╬▒,
//           .╠╬╠╠╬╙,φ╠╠╠╠╠╙ ,╔▒░░░░░░╩╚╙╙``╙╙╚▒░░░░▒φ,  `╠╠╠╠╠╦ ╙╠╠╠╬▒
//          ,╬╠╠╠╜ ╔╠╠▒╠╩  ╔▒░░░░╠╙  ,╓▄╗╗@@╗╥   `╚░░░░▒╓  ╙╬╠╠╠╠╦ ╚╬╬╠╬
//         ╒╠╠╠╠╜ ╠▒▒▒╠  φ░░░░╩╙ ╓@╣╠╠╬╬╠╠╬╬╬╬╬▓╗╖  ╙▒░░░╠   `╠╠╠╠╠ ╠╬╬╬▒
//        ,╬╬╠╠╜ ╠▒▒▒╩ ,╠░░░╩ ,@╬╬╠╬╬╩╝╙╙╙ └╙╣╬╬╬╬▓▌, ╙░░░░▒,  ╚╬╠╠╠ ╬╬╬╬▄
//        ╬╠╠╠╜ ╠▒▒╠╩ ,▒░░░╙ φ╬╠╬╬╩    ,,,     ╙╝╬╬╬╬▒╦ ╙▒░░░▒╓ ╚╠╠╠╬ ╬╬╬╬▄
//       ╔╬▒▒╠ ╠╠╠╠╩ ╔░░░░ ,╣╬╬╠╩  ,φ╠░░░░░░▒φ╦   ╙╣╬╬╬▒▄ ╙╠░░░╦ ╚╠╠╠╬└╬╬╬╬µ
//       ╬╠╠▒ φ▒▒╠╬ ]░░░░ ╔╬╬╬╬╩ ╔▒░░░░╩╚╚╩░░░░░▒╦  ╙╣╬╬╬▓╕ ▒░░░╦ ╠╠╠╠▒╚╬╬╬╣
//      ▐╠╠╠╬]▒╠╠╠  ╠░░░⌐╔╬╬╬╬─╔╠░░░╩╙       ╙╠░░░░╠╓ ╙╣╬╬╬▒ ░░░░ε ╠╠╠╠ ╬╬╬╬
//      ╬╬╠╠Γ╠╠╠╠╩ φ░░░╩╔╬╬╠╣.╩░░░╩  ╓╦╦▒▒▒M╗   ╙╩░░░▒  ╬╬╬╬ ╙░░░▒ ╠╠╠╠µ╚╬╬╬▒
//     ]▒▒╠╠ ▒╠╠╠ ╔░░░▒╒╬╠╠╬ ╠░░░╙,φ╠╠╠╠╠╠╠╠╠╠▒╖  ╠░░░╕ ╠╠╬╬▌ ╚░░░▒╠╠╠╠▒▐╬╬╬╬
//     ╚░░░╙▐╠╠╠╠ ░░░░ ╬╬╬╠▒φ░░░╙╒╠╬╠╠╩╙   ╙╠╠╠╠╬╦ ░░░░ ▐╬╬╬▓  ░░░░▐╠╠╠╠▐╬╬╬╬
//     ░░░░ ╠╠╠╠Γφ░░░╙▐╠╬╠╬▐░░░▒ ╬╠╠╠⌐ ╓╦φ≥╓ ╙╠╠╬╠▒╙░░░╠ ╬╬╬╬  ░░░░ ╠╠╠╠░╬╬╬╬
//     ░░░░ ╠╠╠╠∩░░░░ ╟╬╠╬Γ╠░░░Γ╠╠╠╠╩φ▒▒░▒▒▒╠  ▒╠╠╠ ╚░░░ε╬╬╬╬b ░░░░ ╠╠╠╠ε╬╬╬╬
//     ░░░░ ╬╠╠╠ ░░░░ ╬╬╬╬▒░░░░╒╬╠╠╠]▒░░░╚░▒▒╠ ╠╬╠╠▒╚░░░▒║╬╬╬▌ ░░░░ ╚╠╠╠▒╠╬╬╬▒
//     ░░░░j▒▒▒╠ ░░░░ ╬╬╬╬░░░░▒╬▒╠╠⌐╚░░▒╩ ╙▒▒░╠ ╬╠╠╠⌐░░░░▐╬╬╬╬ ▒░░░ ╠╠╠╠Γ ╬╬╬╬
//      ░░░╔▒▒▒╠ ░░░░ ╬╬╬╬▐░░░Γ▒▒▒╠ ░░░░   ▒▒▒▒ε▒╠╠╠L╚░░▒ ╣╣▓▀ ╙╩╠╩ ╠╬▒╠▒└╬╬╬╠▒
//      ""`╙╠▒╠ ▐░░░╙ ╚╬╬╩╚▒▒▒ ▒╠▒▒j▒▒▒╩   ╙╚╩╩  ╚╜╙                  ╙╙   ╙╙╙
//                             `╙╙   ╙╙
//                                  ▄
// ▐█████                          ███                   ╙███▌   ███████▄ 
//  ▐███ ▄▄▄▄ ▄▄▄   ▄▄▄▄  ,▄▄▄▄▄▄   ▄▄  ▄  ▄▄  ╓▄▄▄▄   ▄▄▄███▌    ███  ███ ▄▄▄   ▄▄▄
//  ▐███  ███▀▀███ ██▄ ▀ ▀███╙▀███ ███  ███▀█ ██▌ ╫██ ███ ╫██▌    ███▄███   ██   █▀
//  ▐███  ███  ███ ▀█████ ███  ███ ███  ██▌   ███▀▀▀▀ ██▌ ╟██▌    ███  ███▌ └██▄▐▌
//  ▐███  ███  ███ ▄  ╢██ ███▄▄███ ███  ██▌   ███▄▄▄█ ███▄███▌    ███▄▄███   ╙███
// └▀▀▀▀▀ ▀▀▀  ▀▀▀ ╙▀▀▀▀  ██▌╙▀▀╙  ▀▀▀ ▀▀▀▀▀   ╙▀▀▀╙   ▀▀▀ ▀▀▀   ▀▀▀▀▀▀▀▀     ╙█
//                       ▄███                                              ████▀
//
// Inspired By, Volume One
// Smart contract created by Ryan Meyers (@sreyemnayr)
// for Jem (@jem) x Sonic Zoo (@SonicZooNFT)
//
//
// Generosity attracts generosity.
//
// The world will be saved by beauty.
//
//
pragma solidity ^0.8.16;

import "IERC2981.sol";
import "draft-EIP712.sol";
import "ERC721.sol";
import "Ownable.sol";
import "ECDSA.sol";
import "Strings.sol";


contract InspiredByVolumeOne is IERC2981, EIP712, ERC721, Ownable {

  struct MintKey {
    address wallet;
  }

  enum Recipient {VARVARA_ALAY, ASLAN_RUBY, RIK_LEE, GABE_WEIS, JEM, DEV, CHARITY, TREASURY}

  Recipient[60] public tokenArtist;
  address[8] public wallets = [
    0x58136e0909b71981F1a37F1f87859c562ed3657a, // Varvara
    0xC841fAbb79C0b39Bd0af850DCD5281022445Eb51, // Aslan Ruby
    0x87AFc8AdAfF6ab99Af285B3e4790b1AaaC2e3461, // Rik Lee
    0x5e93ab46E9A0B39312b5e112d4B053A768203f9F, // Gabe
    0x4F4583c00eafdd7C81154f69Da3690e4ab530E69, // Jem
    0x3D2198fC3907e9D095c2D973D7EC3f42B7C62Dfc, // Dev
    0xB5dfc47d483cfe002EAF6E1140263e62aA6677AD, // Charity
    0x7cc08443Bf7dBF3cA520691cfbb817ac1b560ECf // Treasury
  ];

  bytes32 private constant MINTKEY_TYPE_HASH = keccak256("MintKey(address wallet)");
 
  uint16 private _currentToken;

  uint16 private _royaltyBPS;
  address private _signer;
  
  string private _baseTokenURI;

  uint256 public PRICE = 0.3 ether;
  uint256 public constant MAX_SUPPLY = 60;
  bool public PUBLIC_SALE = false;
  
  mapping(address => bool) private _hasMinted;

  constructor(
    string memory name,
    string memory symbol,
    address signer,
    uint16 royaltyBPS,
    string memory baseTokenURI
  )
    ERC721(name, symbol)
    EIP712(name, "1")
  {
        _signer = signer;
        _royaltyBPS = royaltyBPS;
        _baseTokenURI = baseTokenURI;

        // instantiate tokenArtist
        for(uint256 i = 0; i < MAX_SUPPLY; i++){
          tokenArtist[i] = Recipient.TREASURY;
        }
  }

  // on reveal, set 
  function initializeArtistRoyalties(Recipient artist, uint256[] calldata tokens, address split_wallet) external onlyOwner {
    for(uint256 i = 0; i < tokens.length; i++){
      tokenArtist[tokens[i]] = artist;
    }
    wallets[uint(artist)] = split_wallet;
  }

  function setArtistWallet(Recipient artist, address wallet) external onlyOwner {
    wallets[uint(artist)] = wallet;
  }

  function sendEth() internal {
    // 10% always goes to charity wallet
    require(payable(wallets[uint(Recipient.CHARITY)]).send(msg.value / 10));

    // First 6 mints pay developer stipend
    if(_currentToken < 6){
      uint256 ten_percent = msg.value / 10;
      // Pay Developer
      require(payable(wallets[uint(Recipient.DEV)]).send(ten_percent * 9));
    }
  }

  function seeTheSun(bytes calldata signature) public payable {
    require(_currentToken + 1 < MAX_SUPPLY, "SOLD OUT");

    if(!PUBLIC_SALE){
      require(!_hasMinted[msg.sender], "Already minted presale");
      _hasMinted[msg.sender] = true;
      require(verify(signature), "INVALID MINT KEY");
    }
    require(msg.value >= PRICE, "SENT AMOUNT TOO LOW");
    

    sendEth();
    _safeMint(msg.sender, _currentToken);
    _currentToken++;

  }

  function resetMintedStatus(address[] calldata reset_wallets) external onlyOwner {
    for(uint256 i = 0; i < reset_wallets.length; i++){
      _hasMinted[reset_wallets[i]] = false;
    }
  }

  function goPublic() external onlyOwner {
    PUBLIC_SALE = true;
  }

  // Eject Remaining
  function ejectRainbows() external onlyOwner {
    require(_currentToken < MAX_SUPPLY, "Sold Out");
    while(_currentToken < MAX_SUPPLY){
      _safeMint(wallets[uint(Recipient.JEM)], _currentToken);
      _currentToken++;
    }
  }

  function burn(uint32[] calldata rainbows) external {
    for(uint256 i = 0; i < rainbows.length; i++){
      require(_isApprovedOrOwner(msg.sender, rainbows[i]), "NOT APPROVED FOR TOKEN");
      _burn(rainbows[i]);
    }
  }

  
  function verify(bytes calldata signature) public view returns (bool) {
    bytes32 digest = _hashTypedDataV4(
        keccak256(
            abi.encode(
                MINTKEY_TYPE_HASH,
                msg.sender
            )
        )
    );

    return ECDSA.recover(digest, signature) == _signer;
  }

  function setBaseTokenURI(string calldata baseTokenURI) external onlyOwner {
      _baseTokenURI = baseTokenURI;
  }

  function totalSupply() public view returns (uint16) {
        return _currentToken + 1;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json"));
  }

  function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
  }

  function setRoyaltyBPS(uint16 royaltyBPS_) public onlyOwner {
    _royaltyBPS = royaltyBPS_;
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256) {
        return (wallets[uint(tokenArtist[_tokenId])], ((_salePrice * _royaltyBPS) / 10000));
  }

  function withdraw_all() public payable {
    require(payable(wallets[uint(Recipient.TREASURY)]).send(address(this).balance));
  }

  function withdraw_split() public payable {
    require(payable(wallets[uint(Recipient.JEM)]).send(address(this).balance / 2));
    require(payable(wallets[uint(Recipient.VARVARA_ALAY)]).send(address(this).balance / 8));
    require(payable(wallets[uint(Recipient.GABE_WEIS)]).send(address(this).balance / 8));
    require(payable(wallets[uint(Recipient.ASLAN_RUBY)]).send(address(this).balance / 8));
    require(payable(wallets[uint(Recipient.RIK_LEE)]).send(address(this).balance / 8));
  }

  function getChainId() external view returns (uint256) {
        return block.chainid;
  }

  function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
  }

}