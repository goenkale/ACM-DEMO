package process

import groovy.json.JsonOutput

@Field Contract contract
@Field ResourceBundle messages


//write """
///*
//${toJson(contract?.inputs)}
//*/
//"""


writeContractInputs(contract)

def writeContractInputs(contract) {
	addContractInputs('contractInputs',contract.inputs)
	newLine()
	write "def contractInputs= [:]"
	newLine()
	contract?.inputs?.each{child ->
		def inputName = getInputName(child)
		write "contractInputs.${inputName} = contractInputs_${inputName}"
		newLine()
	}
	write 'return contractInputs'
	newLine()
}


def addContractInputs(prefix, inputs) {
	//	write """
	///* ${prefix}
	//	${toJson(inputs)}
	//	*/
	//"""
	inputs?.each { child ->
		def inputType = getInputType(child)
		def isComplex = isComplex(child)
		def isMultiple = isMultiple(child)
		def childPrefix = getPrefix(prefix, child)
		write "// ${getInputName(child)} - ${getInputType(child)} - ${isComplex? 'complex':'simple'} ${isMultiple? 'multiple':'single'}"
		newLine()
		if (isComplex){
			addComplexInput(childPrefix,child)
		}
		else {
			addSimpleInput (childPrefix,child)
		}
	}

	//	inputs?.each { child ->
	//		def inputType = getInputType(child)
	//		def isComplex = isComplex(child)
	//		def isMultiple = isMultiple(child)
	//		def childPrefix = getPrefix(prefix, child)
	//		//		if (isComplex){
	//		//			addComplexInput(childPrefix,child)
	//		//		}
	//		//		else {
	//		//			addSimpleInput (childPrefix,child)
	//		//		}
	//	}
}


def addComplexInput(prefix,input) {

	write "def ${prefix} = [:] "
	newLine()
	input.children?.each{ child ->
		def inputType = getInputType(child)
		def childIsMultiple = isMultiple(child)
		def isComplex = isComplex(child)
		def isMultiple = isMultiple(child)
		def childPrefix = getPrefix(prefix, child)
		if (isComplex){
			addComplexInput(childPrefix,child)
			newLine()
		}
		else {
			addSimpleInput (childPrefix,child)
		}
	}
	newLine()
	input.children?.each{ child ->
		def childName = getChildName(prefix, child)
		write "${prefix}.${child.name} = ${childName}"
		newLine()
	}
}

def getChildName (prefix,child) {
	def ret= "${prefix}_${child.name}"
	if (isMultiple(child)) {
		return "[ ${ret} ]"
	}
	return ret

}

def addSimpleInput(prefix, input) {
	def inputType = getInputType(input)
	def isMultiple = isMultiple(input)
	def value = '?'
	switch (inputType) {
		case 'TEXT':
			value='"ABCD"'
			break
		case 'LOCALDATE':
			value= 'LocalDate.now()'
			break
		case 'LOCALDATETIME':
			value= 'LocalDateTime.now()'
			break
		case 'DATE':
			value = 'new Date()'
			break
		case 'OFFSETDATETIME':
			value =  'OffsetDateTime.now()'
			break
		case 'INTEGER':
			value='123'
			break
		case 'DECIMAL':
			value='456.78D'
			break
		case 'BOOLEAN':
			value='true'
			break
		case 'FILE':
			writeIndent """def ${prefix}_fileValue =  new FileInputValue("file.txt","Text/plain", "file content".bytes)"""
			newLine()
			value = "${prefix}_fileValue"
			break
		default:
			value = "type ${inputType} is not supported!"
	}
	write "def ${prefix} = ${isMultiple?'[':''}${value}${isMultiple?']':''} /* ${inputType} ${isMultiple?'multiple':'single'} */"
	newLine()
}

def addComplexContractInputReferences(input) {

	def name = input.name.capitalize()
	def nodes = input.children?.each{}

	newLine()
	write """def $name   /*



{
${toJson(input)}
}*/
"""

	newLine()
	write true, "    $nodes"
	newLine()
	write  '} */'
}

def createContractInputNodeDef(prefix, input) {
	def inputName = input.name
	def capitalizedInputName = input.name.capitalize()
	def inputType = input.type.toString().toLowerCase().capitalize()
	def multiple = input.multiple ? ", _multiple_" : ''
	def isComplex = isComplex(input)
	def description = input.description ? "    //${input.description}_" : ''
	def comment = "/* $inputType $description */"

	def node = isComplex
			? "def ${prefix}${inputName} = [:] $comment" //new ${getInputJavaType(input)} _$multiple)$description"
			: "def ${prefix}${inputName} $comment"// inputType ([olive]_${inputType}_$multiple)$description"
}


//def createContractInputNode(input) {
//	def inputName = input.name
//	def capitalizedInputName = input.name.capitalize()
//	def inputType = input.type.toString().toLowerCase().capitalize()
//	def multiple = input.multiple ? ", _multiple_" : ''
//	def isComplex = inputType == "Complex"
//	def description = input.description ? "    //${input.description}_" : ''
//
//	def node = isComplex
//			? "$inputName ([teal]_${capitalizedInputName}_$multiple)$description"
//			: "$inputName ([olive]_${inputType}_$multiple)$description"
//}

def inputName(input) {
	write " ${getInputType(input)} ${input.name} "
}
def inputType(input) {
	write " /* type ${input} */"
}

def writeIndent(message) {
	write "    $message"
}

def isMultiple(input) {
	input?.multiple == true
}


def isComplex(input) {
	'COMPLEX' == getInputType(input)
}

def getInputType(input) {
	input.type?.toString().toUpperCase()
}

def getPrefix(prefix,input) {
	"${prefix}_${getInputName(input)}"
}

def getInputName(input) {
	input.name
}


def toJson(def object) {
	def json =  JsonOutput.toJson(object)
	def pretty = JsonOutput.prettyPrint(json)
	pretty
}
