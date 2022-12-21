//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IControlMint {

    event Event1More( bool event1More, uint256 indexed event1MoreCount, uint256 data );

    event NewAccessFreemint(address indexed newMinter, uint256 data);
    event NewAccessWhitelist(address indexed newMinter, uint256 data);


    struct AccessFreemint { uint32 numMints; bool active; }

    struct AccessWhitelist { uint32 numMints; bool active; uint64 event1MoreCountInit; }

    /**
     * @dev Añade un minter a la lista de freemint
     * @dev Comprueba que no haya llegado al limite: "maxImplementAddressFreemintList"
     * @dev Se incrementa el numero de mints para la freemints
     * @dev Si el minter existe, se añade un mint a sus mints disponibles. Si no tiene ningun mint disponible, su cantidad de mints ahora será de 1.
     */
    function addAddressFreemintList(address[] memory newMinters) external;

    function addAddressWhitelistList(address[] memory newMinters) external;

    /**
     * @dev Recoge el numero de address implementados en la lista de freemint
     */
    function getAddressFreemintListCount() external returns(uint256);

    /**
     * @dev Recoge el numero de address implementados en la lista de whitelist
     */
    function getAddressWhitelistListCount() external returns(uint256);

    /**
     * @dev Comprueba si el minter puede mintear de la freemint
     * @dev Agregar modificador checkAddressIntoList
     */
    function checkMinterFreemint(address minter) external view returns(bool);

    /**
     * @dev Comprueba si el minter puede mintear de la whitelist
     * @dev Agregar modificador checkAddressIntoList
     */
    function checkMinterWhiteList(address minter) external view returns(bool);

    /**
     * @dev El minter reclama su minteo gratis y se desactiva freemint
     * @dev No se elimina para saber que ese address no puede vovler a añadirse
     * @dev Agregar modificador checkAddressIntoList
     */
    function minterUseFreemint(address minter) external returns(bool);

    /**
     * @dev El minter reclama su minteo gratis y se desactiva whitelist
     * @dev No se elimina para saber que ese address no puede volver a añadirse
     * @dev Agregar modificador checkAddressIntoList
     */
    function minterUseWhitelist(address minter) external returns(bool isAddress);

    function activeEvent1MoreWhitelist(bool active) external;

    function getStateEvent1More() external view returns(bool);

    function getMintForAddress(address minter) external view returns(uint32);

    function addMintForAddress(address minter) external;

    function getAvailableMintForAddressWL(address minter) external view returns(uint32);

    function getAvailableMintForAddressFM(address minter) external view returns(uint32);

    function getAvailableMintForAddressPS(address minter) external view returns(uint32);

    function getNumEvent1More() external view returns(uint64);

    function getMintsWhitelistCount() external returns(uint256);

    function getMintsFreemintCount() external returns(uint256);

    function checkAddressActive(address minter) external view returns(bool, bool);

}