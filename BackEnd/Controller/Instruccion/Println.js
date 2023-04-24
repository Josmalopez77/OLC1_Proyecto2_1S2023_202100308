const procesarCadena = require("../../Model/Operacion/Cadena")

function Println(_instruccion, _ambito) {
    const cadena = procesarCadena(_instruccion.expresion, _ambito);
    return cadena;
}

module.exports = Println