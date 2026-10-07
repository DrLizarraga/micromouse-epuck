\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{BitacoraSKv2}[2026/04/24 Clase v2 para bitácoras ITESO, Dr. Jorge A. Lizárraga]

\LoadClass{article}

% =========================================================
% Paquetes
% =========================================================
\RequirePackage[spanish]{babel}
\RequirePackage{graphicx}
\RequirePackage{xcolor}
\RequirePackage{geometry}
\RequirePackage{fancyhdr}
\RequirePackage{float}
\RequirePackage{subfigure}
\RequirePackage{lastpage}
\RequirePackage{hyperref}
\RequirePackage{array}
\RequirePackage{tabularx}
\RequirePackage{tcolorbox}
\RequirePackage{enumitem}
\RequirePackage{amsmath}
\RequirePackage{amssymb}
\RequirePackage{pgfkeys}
\RequirePackage{listingsutf8}
\RequirePackage{tikz}
\tcbuselibrary{skins,breakable}
\RequirePackage{eso-pic}
\RequirePackage[normalem]{ulem}
% =========================================================
% Márgenes
% =========================================================
\geometry{left=1cm,right=1cm,top=1cm,bottom=2cm}
\setlength{\parindent}{0pt}

% =========================================================
% Colores
% =========================================================
\definecolor{myiteso1}{RGB}{7,43,97}
\definecolor{myiteso2}{RGB}{220,234,247}
\definecolor{mygray}{RGB}{240,240,240}

% =========================================================
% Datos generales
% =========================================================
\newcommand{\subtitletext}{Bitácora de trabajo}
\newcommand{\subtitle}[1]{\renewcommand{\subtitletext}{#1}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\RequirePackage{pgfkeys}

% =========================================================
% Tabla: Datos de la bitácora
% =========================================================
\pgfkeys{
	/TablaBitacora/.is family,
	/TablaBitacora,
	Asignatura/.initial  = ,
	Profesor/.initial    = ,
	Equipo/.initial      = ,
	Integrantes/.initial = ,
	Sesion/.initial      = ,
	Fecha/.initial       = ,
	Lugar/.initial       = ,
	Objetivo/.initial    = ,
	Resumen/.initial     = ,
}

% ---------------------------------------------------------
% Alias para claves con espacio inicial
% ---------------------------------------------------------
\pgfkeys{
	/TablaBitacora/ Asignatura/.code  = {\pgfkeys{/TablaBitacora/Asignatura={#1}}},
	/TablaBitacora/ Profesor/.code    = {\pgfkeys{/TablaBitacora/Profesor={#1}}},
	/TablaBitacora/ Equipo/.code      = {\pgfkeys{/TablaBitacora/Equipo={#1}}},
	/TablaBitacora/ Integrantes/.code = {\pgfkeys{/TablaBitacora/Integrantes={#1}}},
	/TablaBitacora/ Sesion/.code      = {\pgfkeys{/TablaBitacora/Sesion={#1}}},
	/TablaBitacora/ Fecha/.code       = {\pgfkeys{/TablaBitacora/Fecha={#1}}},
	/TablaBitacora/ Lugar/.code       = {\pgfkeys{/TablaBitacora/Lugar={#1}}},
	/TablaBitacora/ Objetivo/.code    = {\pgfkeys{/TablaBitacora/Objetivo={#1}}},
	/TablaBitacora/ Resumen/.code     = {\pgfkeys{/TablaBitacora/Resumen={#1}}},
}

\newcommand{\TablaBitacoraValor}[1]{%
	\pgfkeysgetvalue{/TablaBitacora/#1}{\TablaBitacoraTmp}%
	\ifx\TablaBitacoraTmp\pgfutil@empty
	%
	\else
	\TablaBitacoraTmp
	\fi
}

\newcommand{\FilaBitacoraNueva}[2]{%
	#1 & \TablaBitacoraValor{#2} \\ \hline
}

\newcommand{\TablaBitacora}[1]{%
	\pgfkeys{/TablaBitacora/.cd,
		Asignatura=,
		Profesor=,
		Equipo=,
		Integrantes=,
		Sesion=,
		Fecha=,
		Lugar=,
		Objetivo=,
		Resumen=,
		#1
	}%
	\noindent
	\begin{tabular}{|p{0.22\textwidth}|p{0.73\textwidth}|}
		\hline
		\FilaBitacoraNueva{\textbf{Asignatura}}{Asignatura}
		\FilaBitacoraNueva{\textbf{Profesor}}{Profesor}
		\FilaBitacoraNueva{\textbf{Equipo}}{Equipo}
		\FilaBitacoraNueva{\textbf{Integrantes}}{Integrantes}
		\FilaBitacoraNueva{\textbf{Sesión}}{Sesion}
		\FilaBitacoraNueva{\textbf{Fecha}}{Fecha}
		\FilaBitacoraNueva{\textbf{Lugar}}{Lugar}
		\FilaBitacoraNueva{\textbf{Objetivo}}{Objetivo}
		\FilaBitacoraNueva{\textbf{Resumen}}{Resumen}
	\end{tabular}
	\par
}
% =========================================================
% Caja principal
% =========================================================
\newtcbox{\mybox}{
	enhanced,
	colback  = myiteso2,
	colframe = myiteso1,
	boxsep   = 5pt,
	left     = 5pt,
	right    = 5pt,
	top      = 5pt,
	bottom   = 5pt,
	boxrule  = 2pt,
	arc      = 1mm,
	colupper = myiteso1
}

\newtcbox{\typenote}{
	on line,
	colback  = myiteso1,
	colframe = myiteso1,
	boxsep   = 0pt,
	boxrule  = 1pt,
	size     = small,
	arc      = 0mm,
	colupper = myiteso2
}

% =========================================================
% Encabezados y pies de página
% =========================================================
\fancypagestyle{firstpage}{
	\fancyhf{}
	\renewcommand{\headrulewidth}{0pt}
	\renewcommand{\footrulewidth}{0.5pt}
	\fancyfoot[L]{\typenote{\bfseries Bitácora}}
	\fancyfoot[R]{Página \thepage\ de \pageref*{LastPage}}
	\fancyfoot[C]{Instituto Tecnológico y de Estudios Superiores de Occidente}
}

\fancypagestyle{otherspage}{
	\fancyhf{}
	\renewcommand{\headrulewidth}{0pt}
	\renewcommand{\footrulewidth}{0.5pt}
	\fancyhead[L]{\@title}
	\fancyfoot[L]{\typenote{\bfseries Bitácora}}
	\fancyfoot[R]{Página \thepage\ de \pageref*{LastPage}}
	\fancyfoot[C]{Instituto Tecnológico y de Estudios Superiores de Occidente}
}

\pagestyle{otherspage}

% =========================================================
% Configuración de enlaces
% =========================================================
\hypersetup{
	colorlinks = true,
	linkcolor  = blue,
	citecolor  = blue,
	filecolor  = black,
	urlcolor   = blue
}

% =========================================================
% Portada
% =========================================================
\def\maketitle{
	\thispagestyle{firstpage}
	
	\begin{center}
		\mybox{
			\begin{tabular}{m{0.1\textwidth} m{0.8\textwidth}}
				\includegraphics[scale=0.08,trim={0.5cm 3cm 0.5cm 3cm},clip]{figures/logoiteso.png}
				&
				\centering
				\vskip 0.5em
				{\LARGE\bfseries \@title\par}
				\vskip 0.5em
				{\large \subtitletext\par}
				\vskip 0.5em
				{\@author\par}
			\end{tabular}
		}
	\end{center}
	
	\vskip 1em
}

% =========================================================
% Entorno note
% =========================================================
\definecolor{myred1}{RGB}{255,87,51}
\definecolor{myred2}{RGB}{255,233,228}

\newtcolorbox{note}{
	enhanced jigsaw,
	breakable,
	colback  = myred2,
	colframe = myred1,
	boxrule  = 2pt,
	leftrule = 16pt,
	arc      = 1mm,
	left     = 2mm,
	right    = 2mm,
	top      = 1mm,
	bottom   = 1mm,
	overlay  = {
		\node[
		minimum width = 2cm,
		anchor        = center,
		xshift        = 8pt,
		scale         = 2
		] at (frame.west){!};
	}
}
% =========================================================

\AddToShipoutPictureBG{%
	\begin{tikzpicture}[remember picture,overlay]
		\fill[myiteso1]
		(current page.south west)
		rectangle
		([yshift=0.5cm]current page.south east);
		
	\end{tikzpicture}%
	\begin{tikzpicture}[remember picture,overlay]
		\fill[myiteso1]
		([yshift=-0.5cm]current page.north west)
		rectangle
		(current page.north east);
	\end{tikzpicture}%
}

% =========================================================
% Comandos matemáticos útiles
% =========================================================
\newcommand{\abs}[1]{\left|#1\right|}
\newcommand{\norm}[1]{\left\Vert#1\right\Vert}
\newcommand{\un}[1]{\,\text{#1}}
\newcommand{\ld}{$\ldots$}
\newcommand{\sq}{$\square$}

% =========================================================
% Numeración y nombres
% =========================================================
\setcounter{secnumdepth}{1}

\renewcommand{\tablename}{Tabla}
\renewcommand{\figurename}{Figura}

% =========================================================
% Listas
% =========================================================
\setlist[enumerate,1]{label=\textcolor{myiteso1}{\arabic*.}}
\setlist[itemize,1]{label=\textcolor{myiteso1}{\textbullet}}
% ================================================================
% =========== código Arduino ====================
\usepackage{listingsutf8}
\definecolor{arduinoGreen}{rgb}{0.17,0.43,0.01}
\definecolor{arduinoGrey}{rgb}{0.47,0.47,0.33}
\definecolor{arduinoOrange}{rgb}{0.8,0.4,0}
\definecolor{arduinoBlue}{RGB}{37,136,135}
\definecolor{arduinoDarkBlue}{RGB}{60,106,105}
% ========== Define Arduino Language ============
\lstdefinelanguage{ArduinoCustom}{
language = C++,
keywordstyle = \color{arduinoGreen}, 
keywords = {setup, loop, if, do, while, break, return, loop},
% ----------------------------------------------- 
keywordstyle = [2]\color{arduinoBlue}, 
keywords = [2]{HIGH, LOW, OUTPUT, DEC, void, int, float, INPUT, const, INPUT_PULLUP, INPUT_PULLDOWN, double, bool, false, true}, 
% -----------------------------------------------
keywordstyle = [3]\bfseries\color{arduinoOrange}, 
keywords = [3]{Serial, AccelStepper, ezButton}, 
% -----------------------------------------------
keywordstyle = [4]\color{arduinoOrange},
keywords = [4]{begin, pinMode, println, available, read, digitalWrite, delay, print, analogWrite, map, analogRead, digitalRead, setDebounceTime, setAcceleration, setMaxSpeed, moveTo, setSpeed, isReleased, setCurrentPosition, distanceToGo, runSpeed, disableOutputs}, 
% Numbers
    numberstyle = \color{arduinoGreen},
	numbers=left,
	stepnumber=1,
	numbersep=5pt,
	firstnumber=last,
% -----------------------------------------------
basicstyle = \ttfamily\footnotesize,
string = [s]{"}{"},
stringstyle = \color{arduinoDarkBlue},
comment = [l]{//},
commentstyle = \color{arduinoGrey},
escapeinside = ||,
showstringspaces = false,
breaklines = true, 
backgroundcolor = \color{mygray},
tabsize = 1,
literate = 
{á}{{\'{a}}}1
{é}{{\'{e}}}1
{í}{{\'{i}}}1
{ó}{{\'{o}}}1
{ú}{{\'{u}}}1
{ñ}{{\~{n}}}1
}
% =========== código Matlab ====================
\definecolor{myorange2}{RGB}{210,80,16}
\definecolor{light-gray}{gray}{0.95}
\definecolor{mygray}{RGB}{240,240,240}
\definecolor{M1}{RGB}{167,36,240} % Color para cadenas de texto
\definecolor{M2}{RGB}{50,158,50}  % Color para comentarios
\definecolor{M3}{RGB}{0,0,255}    % Color para palabras clave principales
\definecolor{M4}{RGB}{197,0,11}   % Color para funciones y comandos
% ========== Define Matlab Language ============
\lstdefinelanguage{MatlabCustom}{
% ----------------------------------------------- 
    keywordstyle = [1]\color{M3}\bfseries, 
    keywords = [1]{setup,loop,if,do,while, break,end, function,for,else,elseif,switch,case,try,catch,return},
    % ----------------------------------------------- 
    keywordstyle = [2]\color{M1}, 
    keywords = [2]{all,short,on,boxoff, minor,equal,plot,axis,title,xlabel,ylabel,legend,grid,hold,subplot},
    % -----------------------------------------------
    basicstyle = \ttfamily\footnotesize\color{black},
    stringstyle = \color{M1},
    commentstyle = \color{M2},
    string=[s]{"}{"},
    comment=[l]{\%},
	% Numbers
    numberstyle = \color{myorange2},
	numbers=left,
	stepnumber=1,
	numbersep=5pt,
	firstnumber=last,
    % -----------------------------------------------
    escapeinside = {¡}{¡}, % Para insertar LaTeX dentro del código
    showstringspaces = false, 
    breaklines = true, 
    tabsize = 4,
    upquote = true,
    extendedchars = true,
    inputencoding = utf8,
    backgroundcolor = \color{mygray},
    literate = 
    {á}{{\'{a}}}1
    {é}{{\'{e}}}1
    {í}{{\'{i}}}1
    {ó}{{\'{o}}}1
    {ú}{{\'{u}}}1
    {ñ}{{\~{n}}}1
}
\lstnewenvironment{Matlab}{\lstset{language=MatlabCustom}}{}
\lstnewenvironment{Arduino}{\lstset{language=ArduinoCustom}}{}

\endinput





